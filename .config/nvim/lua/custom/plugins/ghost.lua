local function get_env_var(name)
  if os.getenv(name) then
    return os.getenv(name)
  else
    return 'not there, mate'
  end
end

local get_shared_data = function(opts, prompt)
  return {
    system = opts.system_prompt,
    max_tokens = opts.max_tokens,
    messages = prompt,
    stream = opts.stream,
    model = opts.model,
  }
end

local anthropic_content_parser = function(stream)
  local success, json = pcall(vim.json.decode, stream)
  if success and json.delta and json.delta.text then
    return json.delta.text
  end
  return nil
end

local goog_content_parser = function(stream)
  local success, json = pcall(vim.json.decode, stream)
  if
    success
    and json.candidates
    and json.candidates[1]
    and json.candidates[1].content
    and json.candidates[1].content.parts
    and json.candidates[1].content.parts[1]
    and json.candidates[1].content.parts[1].text
  then
    return json.candidates[1].content.parts[1].text
  end
  return nil
end

-- For providers using OpenAI/Hyperbolic style responses
local openai_style_content_parser = function(stream)
  local success, json = pcall(vim.json.decode, stream)
  if success and json.choices and json.choices[1] and json.choices[1].delta and json.choices[1].delta.content then
    return json.choices[1].delta.content
  end
  return nil
end

local function get_anthropic_specific_args(opts, prompt)
  local url = opts.url
  local api_key = opts.api_key_name and get_env_var(opts.api_key_name)

  local data = get_shared_data(opts, prompt)
  local json_data = vim.json.encode(data)

  local args = {
    '--no-buffer',
    '-N',
    url,
    '-H',
    'Content-Type: application/json',
    '-H',
    'anthropic-version: 2023-06-01',
    '-H',
    string.format('x-api-key: %s', api_key),
    '-d',
    json_data,
  }
  return args
end

local function get_goog_specific_args(opts, prompt)
  local url = opts.url .. opts.model .. ':streamGenerateContent?alt=sse&key=' .. get_env_var(opts.api_key_name)

  local data = {
    contents = prompt,
    generationConfig = {
      maxOutputTokens = 4096,
    },
  }
  local json_data = vim.json.encode(data)

  local args = {
    '--no-buffer',
    '-N',
    url,
    '-H',
    'Content-Type: application/json',
    '-d',
    json_data,
  }
  return args
end

local function get_hyperbolic_specific_args(opts, prompt)
  local url = opts.url
  local api_key = opts.api_key_name and get_env_var(opts.api_key_name)

  local data = get_shared_data(opts, prompt)
  data['top_p'] = 0.1
  data['temperature'] = 1

  local json_data = vim.json.encode(data)

  local args = {
    '-v',
    '--no-buffer',
    '-N',
    url,
    '-H',
    'Content-Type: application/json',
    '-H',
    string.format('Authorization: Bearer %s', api_key),
    '-d',
    json_data,
  }
  return args
end

return {
  {
    'lrav35/ghost.nvim',
    -- dir = '~/code/ghost.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      debug = true,
      default = 'anthropic',
      system_prompt = 'you are a helpful assistant, what I am sending you may be notes, code or context provided by our previous conversation',
      providers = {
        anthropic = {
          url = 'https://api.anthropic.com/v1/messages',
          model = 'claude-sonnet-4-20250514',
          event_based = true,
          target_state = 'content_block_delta',
          api_key_name = 'ANTHROPIC_API_KEY',
          max_tokens = 4096,
          curl_args_fn = get_anthropic_specific_args,
          parser = anthropic_content_parser,
          stream = true,
        },
        goog = {
          url = 'https://generativelanguage.googleapis.com/v1beta/models/',
          model = 'gemini-2.5-pro-preview-03-25',
          event_based = false,
          api_key_name = 'GOOG_API_KEY',
          max_tokens = 10000,
          curl_args_fn = get_goog_specific_args,
          parser = goog_content_parser,
          stream = true,
        },
        hyperbolic = {
          url = 'https://api.hyperbolic.xyz/v1/chat/completions',
          model = 'Qwen/QwQ-32B-Preview',
          event_based = false,
          api_key_name = 'HYPERBOLIC_API_KEY',
          max_tokens = 4096,
          curl_args_fn = get_hyperbolic_specific_args,
          parser = openai_style_content_parser,
          stream = true,
        },
      },
      ui = {
        window_width = 70,
        default_message = 'hello, how can I assist you?',
      },
      keymaps = {
        -- Global keymaps
        open = {
          key = '<leader>wo',
          desc = '[W]indow [O]pen chat',
        },
        exit = {
          key = '<leader>we',
          desc = '[W]indow [E]xit chat',
        },
        prompt = {
          key = '<leader>p',
          desc = '[P]rompt',
        },
        save = {
          key = '<leader>ww',
          desc = '[W]indow [W]rite chat',
        },
        load = {
          key = '<leader>wl',
          desc = '[W]indow [L]oad chat',
        },
        cp_buffer = {
          key = '<leader>cb',
          desc = '[C]opy open window [B]uffer',
        },
        -- Buffer-specific keymaps
        buffer = {
          resize_left = {
            key = '<A-h>',
            desc = 'Resize window left',
          },
          resize_right = {
            key = '<A-l>',
            desc = 'Resize window right',
          },
        },
        escape = {
          key = '<Esc>',
          desc = 'Cancel model streaming',
          pattern = 'model_escape_fn',
        },
      },
    },
    config = function(_, opts)
      require('ghost-writer').setup(opts)
    end,
  },
}
