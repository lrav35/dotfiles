local function get_env_var(name)
  if os.getenv(name) then
    return os.getenv(name)
  else
    return 'not there, mate'
  end
end

local anthropic_content_parser = function(stream)
  local success, json = pcall(vim.json.decode, stream)
  if success and json.delta and json.delta.text then
    return json.delta.text
  end
  return nil
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

local function get_redacted_specific_args(opts, prompt)
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
    '-H',
    'use-case: local development assistance',
    '-d',
    json_data,
  }
  return args
end

return {
  {
    dir = os.getenv 'HOME' .. '/code/ghost-writer.nvim',
    -- 'lrav35/ghost-writer.nvim',
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
          model = 'claude-3-5-sonnet-20241022',
          event_based = true,
          target_state = 'content_block_delta',
          api_key_name = 'ANTHROPIC_API_KEY',
          max_tokens = 4096,
          curl_args_fn = get_anthropic_specific_args,
          parser = anthropic_content_parser,
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
        redacted = {
          url = 'REDACTED_API_URL',
          event_based = false,
          api_key_name = 'REDACTED_API_KEY',
          max_tokens = 4096,
          curl_args_fn = get_redacted_specific_args,
          parser = openai_style_content_parser,
          stream = false,
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
          desc = '[W]indow [O]pen Chat',
        },
        exit = {
          key = '<leader>we',
          desc = '[W]indow [E]xit',
        },
        prompt = {
          key = '<leader>p',
          desc = '[P]rompt',
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
