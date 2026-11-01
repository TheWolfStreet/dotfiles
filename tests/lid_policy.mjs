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

function fixture(t, { mirror = "none", external = true, ac = true, inhibited = false } = {}) {
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
	}
	writeFileSync(state, JSON.stringify({ monitors: external ? [panel, tv] : [panel], calls: [] }))
	const hyprctl = join(bin, "hyprctl")
	writeFileSync(hyprctl, `#!${process.execPath}
import fs from "node:fs"
const path = process.env.MONITOR_STATE
const state = JSON.parse(fs.readFileSync(path, "utf8"))
const args = process.argv.slice(2)
const command = args[1] ?? ""
const output = command.match(/output\\s*=\\s*"([^"]*)"/)?.[1]
const disabled = command.match(/disabled\\s*=\\s*(true|false)/)?.[1]
state.calls.push({ args, output, disabled })
const monitor = state.monitors.find((monitor) => monitor.name === output)
if (args[0] === "eval" && monitor && disabled !== undefined) monitor.disabled = disabled === "true"
fs.writeFileSync(path, JSON.stringify(state))
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
		SLEEP_INHIBITED: inhibited ? "1" : "",
	}
	const read = () => JSON.parse(readFileSync(state, "utf8"))
	return {
		runtime,
		read,
		tv: () => read().monitors.find((monitor) => monitor.name === "HDMI-A-1"),
		evals: () => read().calls.filter((call) => call.args[0] === "eval"),
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

for (const mirror of ["none", "eDP-1"])
	test(`closing the lid disables only the panel and stays awake with an external display (mirror=${mirror})`, (t) => {
		const f = fixture(t, { mirror, ac: false })
		const closed = f.close()
		assert.equal(closed.status, 0, closed.stderr)
		assert.equal(f.read().monitors[0].disabled, true)
		assert.equal(f.tv().disabled, false)
		assert.equal(f.tv().mirrorOf, mirror)
		assert.deepEqual(f.evals().map((call) => [call.output, call.disabled]), [["eDP-1", "true"]])
		assert.equal(f.commands(), "")
	})

test("opening the lid restores the panel and leaves the external display alone", (t) => {
	const f = fixture(t, { mirror: "eDP-1", ac: false })
	assert.equal(f.close().status, 0)
	const opened = f.open()
	assert.equal(opened.status, 0, opened.stderr)
	assert.equal(f.read().monitors[0].disabled, false)
	assert.deepEqual(f.evals().map((call) => call.output), ["eDP-1", "eDP-1"])
	assert.equal(f.tv().mirrorOf, "eDP-1")
})

for (const ac of [false, true])
	test(`closing an undocked lid suspends on battery and turns the panel off on AC (AC=${ac})`, (t) => {
		const f = fixture(t, { external: false, ac })
		const result = f.close()
		assert.equal(result.status, 0, result.stderr)
		assert.equal(f.commands(), ac ? "" : "suspend\n")
		assert.equal(f.read().monitors[0].disabled, ac)
		assert.deepEqual(f.evals().map((call) => call.output), ac ? ["eDP-1"] : [])
	})

test("an inhibited suspend on battery turns the panel off instead", (t) => {
	const f = fixture(t, { external: false, ac: false, inhibited: true })
	const result = f.close()
	assert.equal(result.status, 0, result.stderr)
	assert.equal(f.commands(), "suspend\n")
	assert.equal(f.read().monitors[0].disabled, true)
})

test("lid handling refuses a runtime directory that is not private", (t) => {
	const f = fixture(t)
	chmodSync(f.runtime, 0o755)
	assert.notEqual(f.close().status, 0)
	assert.deepEqual(f.read().calls, [])
})
