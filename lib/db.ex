defmodule Db do
  defp get_field_definition(type, required, options \\ []) do
    %{
      "type" => type,
      "required" => required,
      "options" => options
    }
  end

  @doc """
  user_id: user id of whom is requesting import
  phases: list of phases to retrive from data base

  we need user_id to check authorization and phases access
  first we should try from our cache(redis) then if some phases
  remains unresolved query main database to retrive data,
  I really jump over this implementation only returns specific value

  this will emit at maximum 1 query to main db to retrive field definitions
  """

  def get_phase_fields_definitions(_user_id, phases) do
    rtn = %{}

    rtn =
      if phases |> Enum.member?(1) do
        Map.merge(rtn, %{
          1 => %{
            "Responsible" => get_field_definition("email", true),
            "Opportunity" => get_field_definition("short_text", true),
            "Phone" => get_field_definition("short_text", false)
          }
        })
      else
        rtn
      end

    rtn =
      if phases |> Enum.member?(2) do
        Map.merge(rtn, %{
          2 => %{
            "Interests" => get_field_definition("select", true, ["insurance", "investment"])
          }
        })
      else
        rtn
      end

    rtn =
      if phases |> Enum.member?(3) do
        Map.merge(rtn, %{
          3 => %{
            "Closed" => get_field_definition("short_text", true, [])
          }
        })
      else
        rtn
      end

    rtn
  end

  @doc """
  user_id: user id of whom is requesting import
  user_ids: list of user ids  to retrive from data base

  we need user_id to check authorization and user-ids access
  first we should try from our cache(redis) then if some phases
  remains unresolved query main database to retrive data,
  I really jump over this implementation only returns specific value

  this will emit at maximum 1 query to main db to retrive field definitions

  """
  def get_users_by_id(_user_id, user_ids) when is_list(user_ids) do
    all_users = %{
      1 => %{
        "organization_id" => 1,
        "email" => "pedro.nazi@foofy.com"
      },
      2 => %{
        "organization_id" => 2,
        "email" => "alina.briz@barfy.com"
      },
      3 => %{
        "organization_id" => 1,
        "email" => "izaque.brus@foofy.com"
      }
    }

    all_users
    |> Map.to_list()
    |> Enum.filter(fn {id, _} -> user_ids |> Enum.member?(id) end)
    |> Map.new()
  end
end
