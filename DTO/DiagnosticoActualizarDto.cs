using System.ComponentModel.DataAnnotations;

namespace app_02.DTO;

public sealed class DiagnosticoActualizarDto
{
    [Range(1, int.MaxValue)]
    public int IdCita { get; set; }

    [StringLength(50)]
    public string? Nombre { get; set; }

    [Required, StringLength(200, MinimumLength = 2)]
    public string Descripcion { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Tratamiento { get; set; }
}
