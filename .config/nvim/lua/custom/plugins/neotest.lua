return {
  {
    'rcasia/neotest-java',
    ft = 'java',
    dependencies = {
      'mfussenegger/nvim-jdtls',
      'mfussenegger/nvim-dap', -- for the debugger
      'rcarriga/nvim-dap-ui', -- recommended
      'theHamsta/nvim-dap-virtual-text', -- recommended
    },
  },
  {
    'nvim-neotest/neotest',
    event = 'VeryLazy',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-vim-test',
      'vim-test/vim-test',
      'haydenmeade/neotest-jest',
    },
    opts = {
      -- create table for adapters
      adapters = {},
      -- See all config options with :h neotest.Config
      discovery = {
        -- Drastically improve performance in ginormous projects by
        -- only AST-parsing the currently opened buffer.
        enabled = true,
        -- Number of workers to parse files concurrently.
        -- A value of 0 automatically assigns number based on CPU.
        -- Set to 1 if experiencing lag.
        concurrent = 0,
      },
      running = {
        -- Run tests concurrently when an adapter provides multiple commands to run.
        concurrent = true,
      },
      summary = {
        -- Enable/disable animation of icons.
        animated = true,
      },
    },
    config = function(_, opts)
      -- setup jest adapter
      table.insert(
        opts.adapters,
        require 'neotest-jest' {
          jestCommand = 'jest',
          jestConfigFile = 'custom.jest.config.ts',
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        }
      )

      -- setup java adapter
      table.insert(
        opts.adapters,
        require 'neotest-java' {
          junit_jar = nil, -- default: stdpath("data") .. /nvim/neotest-java/junit-platform-console-standalone-[version].jar
          incremental_build = true,
        }
      )

      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters or {}) do
          if type(name) == 'number' then
            if type(config) == 'string' then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == 'table' and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter(config)
              else
                error('Adapter ' .. name .. ' does not support setup')
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end

      -- setup neotest
      require('neotest').setup(opts)
      -- setup logging
      local log = false
      if log == true then
        local filepath = require('neotest.logging'):get_filename()
        vim.notify('Erasing Neotest log file: ' .. filepath, vim.log.levels.WARN)
        vim.fn.writefile({ '' }, filepath)

        -- Enable during Neotest adapter development only.
        local log_level = vim.log.levels.DEBUG
        vim.notify('Logging for Neotest enabled', vim.log.levels.WARN)
        require('neotest.logging'):set_level(log_level)
      end

      local neotest = require 'neotest'
      vim.keymap.set('n', '<leader>ta', function()
        neotest.run.attach()
      end, { desc = 'Attach' })
      vim.keymap.set('n', '<leader>tf', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = 'Run File' })
      vim.keymap.set('n', '<leader>tA', function()
        neotest.run.run(vim.uv.cwd())
      end, { desc = 'Run All Test Files' })
      vim.keymap.set('n', '<leader>tT', function()
        neotest.run.run { suite = true }
      end, { desc = 'Run Test Suite' })
      vim.keymap.set('n', '<leader>tn', function()
        neotest.run.run()
      end, { desc = 'Run Nearest Test' })
      vim.keymap.set('n', '<leader>tl', function()
        neotest.run.run_last()
      end, { desc = 'Run Last' })
      vim.keymap.set('n', '<leader>ts', function()
        neotest.summary.toggle()
      end, { desc = 'Toggle Summary' })
      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open { enter = true, auto_close = true }
      end, { desc = 'Show Output' })
      vim.keymap.set('n', '<leader>tO', function()
        neotest.output_panel.toggle()
      end, { desc = 'Toggle Output Panel' })
      vim.keymap.set('n', '<leader>tt', function()
        neotest.run.stop()
      end, { desc = 'Terminate' })
      vim.keymap.set('n', '<leader>td', function()
        vim.cmd 'Neotest close'
        neotest.summary.close()
        neotest.output_panel.close()
        neotest.run.run { suite = false, strategy = 'dap' }
      end, { desc = 'Debug Nearest Test' })
    end,
  },
}
