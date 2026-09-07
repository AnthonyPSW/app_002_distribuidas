namespace app_02.Views;

/// <summary>
/// Fila de <c>vw_Especialidades</c>. Catalogo de especialidades del
/// Sitio B con la cantidad de doctores de cada una.
/// </summary>
public sealed class Especialidad
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int TotalDoctores { get; set; }
}
