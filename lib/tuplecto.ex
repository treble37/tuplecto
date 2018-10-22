defmodule Tuplecto do
  @moduledoc """
  Documentation for Tuplecto. Some simple helpers when working with Ecto to give back tuple-ized responses
  (e.g., {:ok, model}. Heavily inspired by ecto_shortcuts package.
  """

  require Ecto.Query

  defmacro __using__(opts) do
    repo = Keyword.get(opts, :repo)
    model = Keyword.get(opts, :model)

    unless repo && model do
      raise ArgumentError, """
      expected :repo and model to be given as an option. Example:
      use RepoTuple, repo: User.Repo, model: User
      """
    end

    default_preload = Keyword.get(opts, :default_preload)

    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      def repo do
        unquote(repo)
      end

      def model do
        unquote(model)
      end

      def default_preload do
        unquote(default_preload)
      end

      ######### PRELOADING ##########

      defp pload(preloadable, opts) do
        preloads =
          normalize_pload_list(opts[:preload] || opts[:preloads] || default_preload() || [])

        if Enum.count(preloads) > 0 do
          preloadable |> repo().preload(preloads)
        else
          preloadable
        end
      end

      defp normalize_pload_list(pload_list) do
        case pload_list do
          :* -> model().__schema__(:associations)
          "*" -> model().__schema__(:associations)
          _ -> pload_list
        end
      end

      @doc """
      Fetches a single record that matches filters.

      ## Examples
        User.get_by id: "123-ABC"
        User.get_by [id: "123-ABC"],  preload: [:prizes]

      Returns {:ok, record} if result was found.
      Returns {:error, "Record not found"} if no result was found.
      """

      def unquote(:get_by)(filters, opts \\ []) do
        case repo().get_by(model(), filters, opts) |> pload(opts) do
          nil -> {:error, "#{Macro.to_string(model())} for #{Macro.to_string(filters)} not found"}
          record -> {:ok, record}
        end
      end

      def unquote(:first_of_all)(filters, opts \\ []) do
        from(q in model(), where: ^filters)
        |> repo().all()
        |> List.first()
        |> case do
          nil -> {:error, "#{Macro.to_string(model())} for #{Macro.to_string(filters)} not found"}
          record -> {:ok, record}
        end
      end
    end
  end
end
