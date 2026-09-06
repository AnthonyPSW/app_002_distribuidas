using app_02.Data;
using app_02.DTO;
using app_02.Views;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace app_02.Controllers;

[ApiController]
[Route("api/medicity/distribuida")]
public sealed class MedicityController(AppDbContext context) : ControllerBase
{
    private readonly AppDbContext _context = context;

    // VISTA 1: consulta distribuida general.
    [HttpGet("vistas/general")]
    public async Task<ActionResult<IReadOnlyList<ConsultaGeneral>>> GetVistaGeneral(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.ConsultaGeneral
            .AsNoTracking()
            .OrderBy(x => x.Num)
            .ToListAsync(cancellationToken));
    }

    // VISTA 2: permite comprobar el resultado de sp_InsertarDoctor.
    [HttpGet("vistas/doctores")]
    public async Task<ActionResult<IReadOnlyList<DoctorDetalle>>> GetVistaDoctores(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.Doctores
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .ToListAsync(cancellationToken));
    }

    // VISTA 3: permite comprobar el resultado de sp_ActualizarCitaMedica.
    [HttpGet("vistas/citas")]
    public async Task<ActionResult<IReadOnlyList<CitaMedicaDetalle>>> GetVistaCitas(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.Citas
            .AsNoTracking()
            .OrderBy(x => x.FechaHora)
            .ToListAsync(cancellationToken));
    }

    // PROCESO DEL PROFESOR 1: CREATE distribuido en DOCTOR_SB.
    [HttpPost("procesos/doctores/crear")]
    public async Task<IActionResult> CrearDoctor(
        DoctorCrearDto doctor, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_InsertarDoctor
                    @NOMBRE = {doctor.Nombre},
                    @ID_ESPECIALIDAD = {doctor.IdEspecialidad},
                    @ID_CIUDAD = {doctor.IdCiudad}", cancellationToken);

            return StatusCode(StatusCodes.Status201Created,
                new { mensaje = "Doctor registrado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO DEL PROFESOR 2: UPDATE local en CITA_MEDICA_SA.
    [HttpPut("procesos/citas/{id:int}/actualizar")]
    public async Task<IActionResult> ActualizarCita(
        int id, UpdateCitasDto cita, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_ActualizarCitaMedica
                    @ID = {id},
                    @ID_PACIENTE = {cita.IdPaciente},
                    @ID_DOCTOR = {cita.IdDoctor},
                    @FECHAHORA = {cita.FechaHora}", cancellationToken);

            return Ok(new { mensaje = "Cita medica actualizada correctamente en Sitio A." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO PROPIO 1: CREATE distribuido en DIAGNOSTICO_SB.
    [HttpPost("procesos/diagnosticos/crear")]
    public async Task<IActionResult> CrearDiagnostico(
        DiagnosticoCrearDto diagnostico, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_InsertarDiagnostico
                    @ID_CITA = {diagnostico.IdCita},
                    @NOMBRE = {diagnostico.Nombre},
                    @DESCRIPCION = {diagnostico.Descripcion},
                    @TRATAMIENTO = {diagnostico.Tratamiento}", cancellationToken);

            return StatusCode(StatusCodes.Status201Created,
                new { mensaje = "Diagnostico registrado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO PROPIO 2: UPDATE distribuido en DIAGNOSTICO_SB.
    [HttpPut("procesos/diagnosticos/{id:int}/actualizar")]
    public async Task<IActionResult> ActualizarDiagnostico(
        int id, DiagnosticoActualizarDto diagnostico,
        CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_ActualizarDiagnostico
                    @ID = {id},
                    @ID_CITA = {diagnostico.IdCita},
                    @NOMBRE = {diagnostico.Nombre},
                    @DESCRIPCION = {diagnostico.Descripcion},
                    @TRATAMIENTO = {diagnostico.Tratamiento}", cancellationToken);

            return Ok(new { mensaje = "Diagnostico actualizado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    private ObjectResult SqlFailure(SqlException exception)
    {
        var status = exception.Number switch
        {
            50011 or 50021 or 50301 => StatusCodes.Status404NotFound,
            _ => StatusCodes.Status400BadRequest
        };

        return StatusCode(status, new { mensaje = exception.Message });
    }
}
