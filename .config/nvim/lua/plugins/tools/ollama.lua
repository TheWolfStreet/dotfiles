return {
  "David-Kunz/gen.nvim",

  event = { "BufReadPost", "BufNewFile" },
  opts = {
    model = "llama3:8b-instruct-q4_0",
    host = "localhost",
    port = "11434",
    display_mode = "split", -- Can be "float" or "split".
    show_model = false,
    show_prompt = false,
    no_auto_close = true, -- Never closes the window automatically.
    debug = false, -- Prints errors and the command which is run.
  },

  keys = {
    {
      "<leader>cg",
      ":Gen<CR>",
      mode = { "n", "v" },
      desc = "Ollama actions",
    },
  },
}
