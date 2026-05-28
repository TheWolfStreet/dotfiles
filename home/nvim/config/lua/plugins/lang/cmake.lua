return {
	{ import = "lazyvim.plugins.extras.lang.cmake" },
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters_by_ft = {
				cmake = { "cmake_format" },
			},
			formatters = {
				cmake_format = {
					append_args = {
						"--use-tabchars",
						"--fractional-tab-policy",
						"use-space",
					},
				},
			},
		},
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				cmake = { "cmakelint" },
			},
			linters = {
				cmakelint = {
					args = { "--quiet", "--filter=-whitespace/tabs" },
				},
			},
		},
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			if not opts.sources then
				return
			end

			opts.sources = vim.tbl_filter(function(source)
				local command = source and source.generator and source.generator.opts and source.generator.opts.command
				return command ~= "cmake-lint"
			end, opts.sources)
		end,
	},
}
