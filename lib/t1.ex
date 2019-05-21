defmodule T1 do
  @moduledoc """
  Documentation for T1.
  """

  @doc """
  Hello world.

  ## Examples

      iex> T1.hello()
      :world

  """
  def hello do
    :world
  end

  def get_sample_row(phase, assignee, responsible, opportunity, phone, interest) do
    %{
      "phase" => phase,
      "assignee" => assignee,
      "Responsible" => responsible,
      "Opportunity" => opportunity,
      "Phone" => phone,
      "Interest" => interest
    }
  end

  def sample_test_data() do
    init_data = [
      get_sample_row("1", "1", "foo@bar.com", "XPTO", "41982938238", "insurance"),
      get_sample_row("1", "2-3", "", "XPTO", "41982938238", "insurance"),
      get_sample_row("1", "1-4", "foo@foo.com", "XPTO", "41982938238", "insurance")
    ]
    init_data
  end

  def do_import() do
    data = sample_test_data()
    sanitize_rows(data)
  end

  @doc """
  input_csv_rows contains at maximum 5k rows,
  and its content should be map, something like:
  %{
    "phase" => phase,
     "assignee" => assigness,
    field_1 => ...,
    field_2 => ....,
    .
    .
    .
  }
  """

  def sanitize_rows(input_csv_rows) when is_list(input_csv_rows) do
    invalid_rows_cause_nil_phase =
      input_csv_rows|> Enum.filter(fn x -> Map.get(x, "phase") == nil end)

    input_csv_rows = input_csv_rows -- invalid_rows_cause_nil_phase

    all_phases =
      input_csv_rows|>Enum.map(fn x -> Map.get(x, "phase") end ) |>Enum.uniq|>Enum.map(fn x-> Integer.parse(x)|>elem(0) end )

    phase_defs = Db.get_phase_fields_definitions(0, all_phases)
    db_defined_phases = Map.keys(phase_defs)|>Enum.map(&to_string/1)

    invalid_rows_casue_of_no_def =
      input_csv_rows |> Enum.filter(fn x ->
        Enum.member?(db_defined_phases,Map.get(x, "phase"))==false
      end)

    input_csv_rows = input_csv_rows -- invalid_rows_casue_of_no_def
    input_csv_rows = expand_rows_on_assignees(input_csv_rows)

    unique_assignee_ids =
      input_csv_rows |> Enum.map(fn x -> Map.get(x, "assignee") end)|> Enum.uniq()|> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)

    db_assignee_users = Db.get_users_by_id(0, unique_assignee_ids)
    db_assignee_users_id = Map.keys(db_assignee_users)|>Enum.map(&to_string/1)

    invalid_rows_cause_of_invalid_user_id =
      input_csv_rows|> Enum.filter(fn x ->
        assignee_id = Map.get(x, "assignee")
        Enum.member?(db_assignee_users_id, assignee_id) == false
      end)

    input_csv_rows = input_csv_rows -- invalid_rows_cause_of_invalid_user_id

    phase_validators =
      phase_defs|> Map.to_list()|> Enum.map(fn {phase_id, phase_def} ->
        {phase_id, T1.get_phase_validator(phase_def)}
      end)|> Map.new()

    phase_validation_result =
      input_csv_rows |> Enum.map(fn row ->
        phase = Map.get(row, "phase")
        phase_id = phase|>Integer.parse()|>elem(0)
        phase_validators[phase_id].(row)
      end)

    success_fail =
      Enum.zip(phase_validation_result, input_csv_rows) |> Enum.reduce(%{"success" => [], "failed" => []}, fn {result, row}, acc ->
        if result == %{} do
          acc |> Map.put("success", [row | acc["success"]])
        else
          acc |> Map.put("failed", [{result, row} | acc["failed"]])
        end
      end)

    success_fail
    |> Map.put("invalid_rows_cause_of_invalid_user_id", invalid_rows_cause_of_invalid_user_id)
    |> Map.put("invalid_rows_casue_of_no_def", invalid_rows_casue_of_no_def)
    |> Map.put("invalid_rows_cause_nil_phase", invalid_rows_cause_nil_phase)
  end

  @doc """
  this will expand rows by assinees, means when we have row have
  multiple assignees like 1-4 it will wxpand to two rows with single
  assignee
  """
  def expand_rows_on_assignees(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row ->
      assignee = row |> Map.get("assignee") |> String.split("-")

      if length(assignee) > 1 do
        assignee
        |> Enum.map(fn x ->
          row |> Map.put("assignee", x)
        end)
      else
        row
      end
    end)
    |> List.flatten()
  end

  def get_phase_validator(phase_def) do
    field_validators =
      phase_def
      |> Map.to_list()
      |> Enum.map(fn {field_name, field_def} ->
        %{"type" => type, "required" => required, "options" => options} = field_def
        {field_name, get_field_validator(type, required, options)}
      end)

    fn x ->
      field_validators
      |> Enum.reduce(%{}, fn {field_name, vali}, acc ->
        if vali.(Map.get(x, field_name)) do
          acc
        else
          acc |> Map.put(field_name, "error")
        end
      end)
    end
  end

  def get_field_validator(type, required, options) do
    fn value ->
      req_part =
        case required do
          true -> &Validators.required/1
          false -> &Validators.not_required/1
        end

      type_part =
        case type do
          "email" ->
            &Validators.validate_email/1

          "integer" ->
            &Validators.is_integer/1

          "float" ->
            &Validators.is_float/1

          "select" ->
            fn x ->
              Validators.is_in_options(x, options)
            end

          "short_text" ->
            &Validators.short_text/1
        end

      req_part.(value) and type_part.(value)
    end
  end
end
