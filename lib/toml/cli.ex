defmodule Toml.CLI do
  @moduledoc """
  Command-line interface for TOML conversion and validation.
  """

  @version Mix.Project.config()[:version] || "0.7.0"

  defstruct [:callback, :input, :argv, :opts]

  @spec main([String.t()]) :: no_return()
  def main(args) do
    case args do
      ["--version" | _] ->
        print_version()
        System.halt(0)

      ["-v" | _] ->
        print_version()
        System.halt(0)

      ["version" | _] ->
        print_version()
        System.halt(0)

      _ ->
        opts = parse_args!(args)
        opts.callback.(opts)
        System.halt(0)
    end
  end

  defp print_version do
    IO.puts("toml v#{@version}")
  end

  ## Convert
  # Perform conversion from TOML content to other formats
  # Currently only supports JSON

  defp convert(%__MODULE__{argv: argv}) do
    aliases = [f: :file]
    flags = [file: :string, stdin: :boolean, format: :string, help: :boolean]
    {opts, _} = OptionParser.parse!(argv, aliases: aliases, strict: flags)

    # Show help if requested via flag
    if opts[:help] do
      help(["convert"])
      System.halt(0)
    end

    # Validate required opts
    if !(opts[:format] && (opts[:file] || opts[:stdin])) do
      warn!("You must provide both --format, and either --file or --stdin")
      help(["convert"])
      System.halt(1)
    end

    # Validate format
    if opts[:format] != "json" do
      fail!("Invalid conversion format '#{opts[:format]}'. Supported formats are: 'json'.")
    end

    input = input(opts)

    case parse(input) do
      {:ok, result} ->
        IO.puts([?\n, Jason.encode!(result, pretty: true)])

      {:error, _} = err ->
        fail!(err)
    end
  end

  ## Validate
  # Validate a TOML document

  defp validate(%__MODULE__{argv: argv}) do
    aliases = [f: :file]
    flags = [file: :string, stdin: :boolean, help: :boolean, quiet: :boolean]
    {opts, _} = OptionParser.parse!(argv, aliases: aliases, strict: flags)

    # Show help if requested
    if opts[:help] do
      help(["validate"])
      System.halt(0)
    end

    # Validate required opts
    if !(opts[:file] || opts[:stdin]) do
      warn!("You must provide either --file or --stdin")
      help(["validate"])
      System.halt(1)
    end

    # Validate
    quiet? = opts[:quiet]
    input = input(opts)

    case parse(input) do
      {:ok, _} ->
        :ok

      {:error, _} when quiet? ->
        System.halt(1)

      {:error, {:invalid_toml, reason}} when is_binary(reason) ->
        fail!(reason)
    end
  end

  # Determine TOML input from options
  defp input(opts) do
    if opts[:stdin] do
      IO.stream(:stdio, :line)
    else
      opts[:file]
    end
  end

  ## Help
  # Display global help, or command help

  defp show_help(%__MODULE__{argv: argv}) do
    help(argv)
  end

  defp help([]) do
    IO.puts("""
    toml - A utility program for TOML, written in Elixir

    Usage:
      toml [flags]
      toml [command] [flags]
      
    Available Commands:
      convert   Convert TOML content to another format.
      validate  Validate TOML content.
      version   Print version information.
      help      Show help
    """)
  end

  defp help(["convert" | _]) do
    IO.puts("""
    Converts TOML content to another format.

    Currently, only JSON is supported.

    Usage:
      toml convert [flags]
      
    Flags:
      -f, --file       Specify a file to convert
      --stdin          Read TOML content from standard input
      --format string  Specify the format to convert to
    """)
  end

  defp help(["validate" | _]) do
    IO.puts("""
    Validates TOML content.

    Exits with a status code of zero if valid, non-zero if invalid.

    Validation errors will be printed to standard error.

    Usage:
      toml validate [flags]
      
    Flags:
      -f, --file      Specify a file to validate
      --stdin         Read TOML content from standard input
      --quiet         Do not print errors, just exit
    """)
  end

  defp help(["version" | _]) do
    print_version()
  end

  defp help(["help"]) do
    IO.puts("""
    Displays help for toml, or for a specific toml command.

    Usage:
      toml help
      toml help [command]
    """)
  end

  defp help(["help" | rest]) do
    help(rest)
  end

  defp help([command]) do
    warn!("Unknown command: #{command}")
    help([])
  end

  # Parse raw args to configuration struct
  defp parse_args!(args) do
    # When run under toml-test, we can't accept arguments
    if System.get_env("TOML_TEST") == "true" do
      %__MODULE__{callback: &convert/1, argv: ["--stdin", "--format", "json"], opts: []}
    else
      {opts, argv} =
        OptionParser.parse_head!(args,
          strict: [help: :boolean, version: :boolean],
          aliases: [h: :help, v: :version]
        )

      cond do
        opts[:version] ->
          %__MODULE__{callback: fn _ -> print_version() end, opts: opts, argv: argv}

        opts[:help] ->
          %__MODULE__{callback: &show_help/1, opts: opts, argv: argv}

        true ->
          case argv do
            ["convert" | argv] ->
              %__MODULE__{callback: &convert/1, opts: opts, argv: argv}

            ["validate" | argv] ->
              %__MODULE__{callback: &validate/1, opts: opts, argv: argv}

            ["version" | _] ->
              %__MODULE__{callback: fn _ -> print_version() end, opts: opts, argv: argv}

            _ ->
              %__MODULE__{callback: &show_help/1, opts: opts, argv: argv}
          end
      end
    end
  end

  # Parse the given input with the appropriate parser
  defp parse(input) when is_binary(input),
    do: Toml.decode_file(input)

  defp parse(stream),
    do: Toml.decode_stream(stream)

  # Write an error to stderr and halt non-zero
  @spec fail!(term()) :: no_return()
  defp fail!(reason) when is_binary(reason) do
    IO.puts(:standard_error, reason)
    System.halt(1)
  end

  defp fail!({:error, reason}) when is_binary(reason) do
    IO.puts(:standard_error, reason)
    System.halt(1)
  end

  defp fail!({:error, reason}) do
    IO.puts(:standard_error, "Error: #{inspect(reason)}")
    System.halt(1)
  end

  # Write a warning to stderr
  defp warn!(msg) when is_binary(msg) do
    IO.puts(:standard_error, msg)
  end
end
