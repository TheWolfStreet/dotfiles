import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import {
	chmodSync,
	mkdtempSync,
	mkdirSync,
	readFileSync,
	rmSync,
	writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"

function fixture(t, { mirror = "none", external = true, ac = true, fault = "" } = {}) {
	const root = mkdtempSync(join(tmpdir(), "lid-policy-"))
	t.after(() => rmSync(root, { recursive: true, force: true }))
	const runtime = join(root, "runtime")
	const bin = join(root, "bin")
	mkdirSync(runtime, { mode: 0o700 })
	mkdirSync(bin)
	const state = join(root, "monitors.json")
	const systemctl = join(root, "systemctl.log")
	const panel = {
		id: 0,
		name: "eDP-1",
		width: 1920,
		height: 1200,
		refreshRate: 144,
		x: 0,
		y: 0,
		scale: 1,
		transform: 0,
		disabled: false,
		dpmsStatus: true,
		mirrorOf: "none",
		advertised: true,
	}
	const tv = {
		...panel,
		id: 2,
		name: "HDMI-A-1",
		width: 3840,
		height: 2160,
		refreshRate: 30,
		x: mirror === "none" ? 1920 : 0,
		mirrorOf: mirror,
		advertised: mirror === "none",
	}
	writeFileSync(state, JSON.stringify({ monitors: external ? [panel, tv] : [panel], calls: [] }))
	const hyprctl = join(bin, "hyprctl")
	writeFileSync(hyprctl, `#!${process.execPath}
import fs from "node:fs"
const path = process.env.MONITOR_STATE
const state = JSON.parse(fs.readFileSync(path, "utf8"))
const args = process.argv.slice(2)
const fault = process.env.FAULT
const command = args[1] ?? ""
const text = (key) => {
	const match = command.match(new RegExp(key + '\\\\s*=\\\\s*("(?:[^"\\\\\\\\]|\\\\\\\\.)*")'))
	return match ? JSON.parse(match[1]) : undefined
}
const output = text("output")
const mirror = text("mirror")
const disabled = command.match(/disabled\\s*=\\s*(true|false)/)?.[1]
state.calls.push({ args, output, mirror, disabled })
let failed = false
if (args[0] === "eval") {
	const monitor = state.monitors.find((monitor) => monitor.name === output)
	if (monitor) {
		failed = (fault === "disable" && disabled === "true" && output !== "eDP-1") ||
			(fault === "enable" && mirror === "none" && output !== "eDP-1")
		if (!failed &&
			!(fault === "stuck" && disabled === "true" && output !== "eDP-1") &&
			!(fault === "stuck_enable" && mirror === "none" && output !== "eDP-1")) {
			const was_disabled = monitor.disabled
			if (disabled !== undefined) monitor.disabled = disabled === "true"
			if (mirror !== undefined) monitor.mirrorOf = mirror
			monitor.advertised = !monitor.disabled && monitor.mirrorOf === "none" &&
				(was_disabled || monitor.advertised)
		}
	}
}
fs.writeFileSync(path, JSON.stringify(state))
if (failed) process.exit(1)
if (args[0] === "monitors") console.log(JSON.stringify(state.monitors.filter((monitor) => args.includes("all") || !monitor.disabled)))
else console.log("ok")
`)
	chmodSync(hyprctl, 0o755)
	const env = {
		...process.env,
		PATH: `${bin}:${process.env.PATH}`,
		XDG_RUNTIME_DIR: runtime,
		MONITOR_STATE: state,
		SYSTEMCTL_LOG: systemctl,
		LID_STATE: "closed",
		AC_ONLINE: ac ? "1" : "0",
		FAULT: fault,
	}
	return {
		runtime,
		read: () => JSON.parse(readFileSync(state, "utf8")),
		commands: () => {
			try {
				return readFileSync(systemctl, "utf8")
			} catch (error) {
				if (error.code === "ENOENT") return ""
				throw error
			}
		},
		close: () => spawnSync("bash", [process.env.LID_CLOSE], { env, encoding: "utf8", timeout: 10000 }),
		open: () => spawnSync("bash", [process.env.RESTORE_PANEL], {
			env: { ...env, LID_STATE: "open" }, encoding: "utf8", timeout: 10000,
		}),
	}
}

for (const mirror of ["eDP-1", "0"])
	test(`closing a mirrored lid republishes the TV before disabling the panel (${mirror})`, (t) => {
		const f = fixture(t, { mirror, ac: false })
		const closed = f.close()
		assert.equal(closed.status, 0, closed.stderr)
		const { monitors, calls } = f.read()
		assert.equal(monitors[0].disabled, true)
		assert.equal(monitors[1].disabled, false)
		assert.equal(monitors[1].mirrorOf, "none")
		assert.equal(monitors[1].advertised, true)
		const changed = calls.filter((call) => call.args[0] === "eval")
		assert.deepEqual(changed.map((call) => [call.output, call.disabled, call.mirror]), [
			["HDMI-A-1", "true", undefined],
			["HDMI-A-1", "false", "none"],
			["eDP-1", "true", undefined],
		])
		assert.equal(f.commands(), "")
		const opened = f.open()
		assert.equal(opened.status, 0, opened.stderr)
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[1].mirrorOf, "eDP-1")
	})

test("closing an extended lid leaves the TV enabled and advertised", (t) => {
	const f = fixture(t, { ac: false })
	const result = f.close()
	assert.equal(result.status, 0, result.stderr)
	assert.equal(f.read().monitors[0].disabled, true)
	assert.equal(f.read().monitors[1].advertised, true)
	assert.equal(f.read().calls.filter((call) => call.args[0] === "eval").length, 1)
	assert.equal(f.commands(), "")
})

for (const fault of ["disable", "enable", "stuck", "stuck_enable"])
	test(`failed TV promotion keeps the panel available and restores the mirror (${fault})`, (t) => {
		const f = fixture(t, { mirror: "eDP-1", fault })
		assert.notEqual(f.close().status, 0)
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[1].disabled, false)
		assert.equal(f.read().monitors[1].mirrorOf, "eDP-1")
		assert.equal(f.commands(), "")
	})

for (const ac of [false, true])
	test(`closing an undocked lid preserves the power policy (AC=${ac})`, (t) => {
		const f = fixture(t, { external: false, ac })
		const result = f.close()
		assert.equal(result.status, 0, result.stderr)
		assert.equal(f.commands(), ac ? "" : "suspend\n")
	})

test("lid handling refuses a runtime directory that is not private", (t) => {
	const f = fixture(t)
	chmodSync(f.runtime, 0o755)
	assert.notEqual(f.close().status, 0)
	assert.deepEqual(f.read().calls, [])
})
