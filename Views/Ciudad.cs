namespace app_02.Views;

/// <summary>
/// Fila de <c>vw_Ciudades</c>. Catalogo de ciudades del Sitio A con sus
/// pacientes locales y los doctores remotos asignados.
/// </summary>
public sealed class Ciudad
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int TotalPacientes { get; set; }
    public int TotalDoctores { get; set; }
}
