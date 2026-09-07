using System.ComponentModel.DataAnnotations;

namespace app_02.DTO;

public sealed class CitaCrearDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un paciente valido.")]
    public int IdPaciente { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un doctor valido.")]
    public int IdDoctor { get; set; }

    public DateTime FechaHora { get; set; }
}
