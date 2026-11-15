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
		hardwareDetails: { backend: "drm" },
		activeWorkspace: { address: "1", id: 1, type: "normal", name: "1" },
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
const output = command.match(/(?:output|monitor)\\s*=\\s*"([^"]*)"/)?.[1]
const disabled = command.match(/disabled\\s*=\\s*(true|false)/)?.[1]
const action = command.match(/action\\s*=\\s*"([^"]*)"/)?.[1]
const mirror = command.match(/mirror\\s*=\\s*"([^"]*)"/)?.[1]
state.calls.push({ args, output, disabled, action, mirror })
const monitor = state.monitors.find((monitor) => monitor.name === output)
if (args[0] === "eval" && monitor && disabled !== undefined) monitor.disabled = disabled === "true"
if (args[0] === "eval" && monitor && mirror !== undefined) {
    const target = state.monitors.find((monitor) => monitor.name === mirror)
    if (target && target.mirrorOf !== "none") {
        console.error("Cannot mirror a mirror")
        process.exit(1)
    }
    monitor.mirrorOf = target ? String(target.id) : "none"
}
if (args[0] === "eval" && command.includes(":set_workspace(")) {
    const name = command.match(/hl.get_monitor\\("([^"]*)"\\)/)?.[1]
    const workspace = command.match(/:set_workspace\\("([^"]*)"\\)/)?.[1]
    const source = state.monitors.find((monitor) => monitor.name === name && monitor.mirrorOf === "none")
    if (!source) process.exit(1)
    source.activeWorkspace = { address: workspace, name: workspace, type: "normal" }
}
if (args[0] === "dispatch" && command.startsWith("hl.dsp.dpms(")) {
    const selected = state.monitors.find((monitor) => monitor.name === output && monitor.mirrorOf === "none" && !monitor.disabled)
    for (const monitor of state.monitors)
        if (!monitor.disabled && (selected === undefined || monitor === selected)) monitor.dpmsStatus = action === "on"
}
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
		change: (update) => {
			const current = read()
			update(current)
			writeFileSync(state, JSON.stringify(current))
		},
		saved: () => readFileSync(join(runtime, `hypr-internal-panel-${process.getuid()}`), "utf8"),
		tv: () => read().monitors.find((monitor) => monitor.name === "HDMI-A-1"),
		evals: () => read().calls.filter((call) => call.args[0] === "eval" && call.args[1].startsWith("hl.monitor(")),
		dpms: () => read().calls.filter((call) => call.args[0] === "dispatch" && call.args[1].startsWith("hl.dsp.dpms(")),
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
		wake: () => spawnSync("bash", [process.env.WAKE_DISPLAY], { env, encoding: "utf8", timeout: 10000 }),
	}
}

for (const mirror of ["none", "eDP-1", "0"])
	test(`closing a docked lid powers off the panel and uses the external display as its source (mirror=${mirror})`, (t) => {
		const f = fixture(t, { mirror, ac: false })
		const closed = f.close()
		assert.equal(closed.status, 0, closed.stderr)
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[0].dpmsStatus, false)
		assert.equal(f.read().monitors[0].mirrorOf, "2")
		assert.equal(f.tv().disabled, false)
		assert.equal(f.tv().dpmsStatus, true)
		assert.equal(f.tv().mirrorOf, "none")
		assert.deepEqual(f.evals().map((call) => [call.output, call.mirror]), mirror === "none" ? [["eDP-1", "HDMI-A-1"]] : [["HDMI-A-1", ""], ["eDP-1", "HDMI-A-1"]])
		assert.deepEqual(f.dpms().map((call) => [call.output, call.action]), [["eDP-1", "off"]])
		assert.equal(f.commands(), "")
	})

for (const mirror of ["none", "0"])
	test(`opening the lid restores the panel and original external mirror relationship (mirror=${mirror})`, (t) => {
		const f = fixture(t, { mirror, ac: false })
		assert.equal(f.close().status, 0)
		const opened = f.open()
		assert.equal(opened.status, 0, opened.stderr)
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[0].dpmsStatus, true)
		assert.equal(f.read().monitors[0].mirrorOf, "none")
		assert.deepEqual(f.evals().map((call) => call.output), mirror === "none" ? ["eDP-1", "eDP-1"] : ["HDMI-A-1", "eDP-1", "eDP-1", "HDMI-A-1"])
		assert.equal(f.tv().mirrorOf, mirror)
		assert.equal(f.read().calls.some((call) => call.args[0] === "reload"), false)
	})

test("repeated lid handling does not overwrite the saved layout or reapply the mirror", (t) => {
	const f = fixture(t)
	assert.equal(f.close().status, 0)
	const saved = f.saved()
	assert.equal(f.close().status, 0)
	assert.equal(f.saved(), saved)
	assert.equal(f.evals().length, 1)
	assert.equal(f.read().monitors[0].dpmsStatus, false)
})

test("multiple external mirrors are rerouted without creating mirror chains and restored on open", (t) => {
	const f = fixture(t, { mirror: "0" })
	f.change((state) => state.monitors.push({ ...state.monitors[1], id: 3, name: "DP-1" }))
	assert.equal(f.close().status, 0)
	assert.deepEqual(f.read().monitors.map((monitor) => monitor.mirrorOf), ["2", "none", "2"])
	assert.equal(f.open().status, 0)
	assert.deepEqual(f.read().monitors.map((monitor) => monitor.mirrorOf), ["none", "0", "0"])
})

test("a powered-on internal mirror is powered off before remirroring without powering off its source", (t) => {
	const f = fixture(t)
	f.change((state) => { state.monitors[0].mirrorOf = "2" })
	assert.equal(f.close().status, 0)
	assert.equal(f.read().monitors[0].mirrorOf, "2")
	assert.equal(f.read().monitors[0].dpmsStatus, false)
	assert.equal(f.tv().dpmsStatus, true)
	assert.deepEqual(f.evals().map((call) => call.mirror), ["", "HDMI-A-1"])
})

for (const ac of [false, true])
	test(`unplugging the external display preserves the panel output and applies the undocked power policy (AC=${ac})`, (t) => {
		const f = fixture(t, { ac })
		assert.equal(f.close().status, 0)
		const saved = f.saved()
		f.change((state) => {
			state.monitors = state.monitors.filter((monitor) => monitor.name !== "HDMI-A-1")
			state.monitors[0].mirrorOf = "none"
		})
		assert.equal(f.close().status, 0)
		assert.equal(f.read().monitors.length, 1)
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[0].dpmsStatus, false)
		assert.equal(f.commands(), ac ? "" : "suspend\n")
		assert.equal(f.saved(), saved)
		assert.equal(f.open().status, 0)
		assert.equal(f.read().monitors[0].dpmsStatus, true)
		assert.equal(f.read().monitors[0].mirrorOf, "none")
	})

test("plugging in an external display with the lid closed creates a powered-off mirror", (t) => {
	const f = fixture(t, { external: false })
	assert.equal(f.close().status, 0)
	f.change((state) => state.monitors.push({ ...state.monitors[0], id: 2, name: "HDMI-A-1", dpmsStatus: true }))
	assert.equal(f.close().status, 0)
	assert.equal(f.read().monitors[0].disabled, false)
	assert.equal(f.read().monitors[0].dpmsStatus, false)
	assert.equal(f.read().monitors[0].mirrorOf, "2")
	assert.equal(f.tv().dpmsStatus, true)
	assert.equal(f.commands(), "")
})

test("headless fallback outputs do not prevent undocked battery suspension", (t) => {
	const f = fixture(t, { ac: false })
	f.change((state) => { state.monitors[1].hardwareDetails.backend = "headless" })
	assert.equal(f.close().status, 0)
	assert.equal(f.commands(), "suspend\n")
	assert.deepEqual(f.evals(), [])
})

for (const mirror of ["none", "0"])
	test(`waking a docked closed laptop wakes only the external display (mirror=${mirror})`, (t) => {
		const f = fixture(t, { mirror })
		assert.equal(f.close().status, 0)
		f.change((state) => { state.monitors[1].dpmsStatus = false })
		const result = f.wake()
		assert.equal(result.status, 0, result.stderr)
		assert.equal(f.read().monitors[0].dpmsStatus, false)
		assert.equal(f.tv().dpmsStatus, true)
		assert.equal(f.tv().mirrorOf, "none")
	})

test("waking multiple external mirrors does not leave the closed internal panel powered on", (t) => {
	const f = fixture(t, { mirror: "0" })
	f.change((state) => state.monitors.push({ ...state.monitors[1], id: 3, name: "DP-1" }))
	assert.equal(f.close().status, 0)
	f.change((state) => { for (const monitor of state.monitors) monitor.dpmsStatus = false })
	assert.equal(f.wake().status, 0)
	assert.deepEqual(f.read().monitors.map((monitor) => monitor.dpmsStatus), [false, true, true])
})

for (const ac of [false, true])
	test(`closing an undocked lid suspends on battery and turns the panel off on AC (AC=${ac})`, (t) => {
		const f = fixture(t, { external: false, ac })
		const result = f.close()
		assert.equal(result.status, 0, result.stderr)
		assert.equal(f.commands(), ac ? "" : "suspend\n")
		assert.equal(f.read().monitors[0].disabled, false)
		assert.equal(f.read().monitors[0].dpmsStatus, !ac)
		assert.deepEqual(f.evals(), [])
		assert.deepEqual(f.dpms().map((call) => [call.output, call.action]), ac ? [["eDP-1", "off"]] : [])
	})

test("an inhibited suspend on battery turns the panel off without removing the last output", (t) => {
	const f = fixture(t, { external: false, ac: false, inhibited: true })
	const result = f.close()
	assert.equal(result.status, 0, result.stderr)
	assert.equal(f.commands(), "suspend\n")
	assert.equal(f.read().monitors[0].disabled, false)
	assert.equal(f.read().monitors[0].dpmsStatus, false)
	assert.deepEqual(f.evals(), [])
	assert.deepEqual(f.dpms().map((call) => [call.output, call.action]), [["eDP-1", "off"]])
})

test("opening an undocked lid wakes the existing output without removing or recreating it", (t) => {
	const f = fixture(t, { external: false })
	assert.equal(f.close().status, 0)
	assert.equal(f.read().monitors[0].dpmsStatus, false)
	const opened = f.open()
	assert.equal(opened.status, 0, opened.stderr)
	assert.equal(f.read().monitors[0].disabled, false)
	assert.equal(f.read().monitors[0].dpmsStatus, true)
	assert.deepEqual(f.evals(), [])
})

test("lid handling refuses a runtime directory that is not private", (t) => {
	const f = fixture(t)
	chmodSync(f.runtime, 0o755)
	assert.notEqual(f.close().status, 0)
	assert.deepEqual(f.read().calls, [])
})
