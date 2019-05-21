defmodule Validators do
  def required(x) when is_binary(x) do
    (x || "") != ""
  end
  def required(nil) do
    false
  end

  def not_required(_) do
    true
  end

  def is_integer(x) when is_binary(x) do
    Regex.match?(~r/^(-+)?[0-9]+$/, x)
  end
  def is_integer(nil) do
    false
  end

  def is_float(x) when is_binary(x) do
    Regex.match?(~r/^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$/, x)
  end
  def is_float(nil) do
    false
  end

  def validate_email(email) when is_binary(email) do
    case Regex.run(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      nil ->
        false

      [_] ->
        true
    end
  end
  def validate_email(nil) do
    false
  end

  def is_in_options(x, options) when is_binary(x) and is_list(options) do
    options |> Enum.member?(x)
  end
  def is_in_options(nil, _) do
    false
  end

  def short_text(x) when is_binary(x) do
    String.length(x) < 256
  end
  def short_text(nil) do
    false
  end
end
