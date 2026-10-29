hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 5,
		col = {
			active_border = { colors = { "rgba(7287fdee)", "rgba(04a5e5ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "scrolling",
		-- Moving focus past the end of the strip does nothing, instead of jumping to the window at the screen's other edge
		no_focus_fallback = true,
	},

	decoration = {
		rounding = false,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
		},
		blur = {
			enabled = true,
		},
	},

	animations = {
		enabled = false,
	},
})

hl.config({
	scrolling = {
		fullscreen_on_one_column = false,
		-- Two columns must span the whole view, or the layout pins the strip centered and ALT + N can't center one
		column_width = 0.5,
	},
})

for _, ns in ipairs({
	"quickshell-topbar",
	"quickshell-settings",
	"quickshell-launcher",
	"quickshell-calendar",
	"quickshell-notifications",
	"quickshell-toasts",
}) do
	hl.layer_rule({
		name = "blur-" .. ns,
		match = { namespace = ns },
		blur = true,
		ignore_alpha = 0,
	})
end
