defmodule YourApp.Commit do
  use Committee

  defp mix_task(task), do: mix_task(task, [])

  defp mix_task(task, params) do
    {
      task,
      System.cmd(
        "mix",
        [task] ++ params,
        env: [{"MIX_ENV", "test"}]
      )
    }
  end

  @impl true
  @doc """
  This function auto-runs `mix coveralls`, `mix test` and `mix credo` + `mix format` on staged files.
  """
  def pre_commit do
    with {"format", {_, 0}} <- mix_task("format"),
         {"test", {_, 0}} <- mix_task("test"),
         {"credo", {_, 0}} <- mix_task("credo", ["--strict"]),
         {"coveralls", {_, 0}} <- mix_task("coveralls") do
      #  System.cmd("git", ["add"] ++ staged_files())
      {:ok, "everything's good"}
    else
      {"format", _} -> {:halt, "format failed"}
      {"test", _} -> {:halt, "test failed"}
      {"credo", _} -> {:halt, "credo failed"}
      {"coveralls", _} -> {:halt, "coverage failed"}
    end
  end
end
