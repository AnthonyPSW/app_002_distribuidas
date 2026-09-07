namespace app_02.Views;

/// <summary>Paciente disponible para los formularios de citas.</summary>
public sealed class Paciente
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Ciudad { get; set; } = string.Empty;
}
