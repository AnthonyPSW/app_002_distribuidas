using app_02.Views;
using Microsoft.EntityFrameworkCore;

namespace app_02.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options)
    : DbContext(options)
{
    public DbSet<ConsultaGeneral> ConsultaGeneral => Set<ConsultaGeneral>();
    public DbSet<DoctorDetalle> Doctores => Set<DoctorDetalle>();
    public DbSet<CitaMedicaDetalle> Citas => Set<CitaMedicaDetalle>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ConsultaGeneral>(entity =>
        {
            entity.HasNoKey();
            entity.ToView("consulta_general");
            entity.Property(x => x.Num).HasColumnName("NUM");
            entity.Property(x => x.IdCita).HasColumnName("ID_CITA");
            entity.Property(x => x.IdDiagnostico).HasColumnName("ID_DIAGNOSTICO");
            entity.Property(x => x.NombreDiagnostico).HasColumnName("NOMBRE_DIAGNOSTICO");
            entity.Property(x => x.Paciente).HasColumnName("PACIENTE");
            entity.Property(x => x.FechaNacimiento).HasColumnName("FECHA_NACIMIENTO");
            entity.Property(x => x.Direccion).HasColumnName("DIRECCION");
            entity.Property(x => x.CiudadPaciente).HasColumnName("CIUDAD_PACIENTE");
            entity.Property(x => x.Doctor).HasColumnName("DOCTOR");
            entity.Property(x => x.CiudadDoctor).HasColumnName("CIUDAD_DOCTOR");
            entity.Property(x => x.Especialidad).HasColumnName("ESPECIALIDAD");
            entity.Property(x => x.FechaHora).HasColumnName("FECHAHORA");
            entity.Property(x => x.Descripcion).HasColumnName("DESCRIPCION");
            entity.Property(x => x.Tratamiento).HasColumnName("TRATAMIENTO");
        });

        modelBuilder.Entity<DoctorDetalle>(entity =>
        {
            entity.HasNoKey();
            entity.ToView("vw_DoctorDetalle");
            entity.Property(x => x.Id).HasColumnName("ID");
            entity.Property(x => x.Doctor).HasColumnName("DOCTOR");
            entity.Property(x => x.IdEspecialidad).HasColumnName("ID_ESPECIALIDAD");
            entity.Property(x => x.Especialidad).HasColumnName("ESPECIALIDAD");
            entity.Property(x => x.IdCiudad).HasColumnName("ID_CIUDAD");
            entity.Property(x => x.Ciudad).HasColumnName("CIUDAD");
        });

        modelBuilder.Entity<CitaMedicaDetalle>(entity =>
        {
            entity.HasNoKey();
            entity.ToView("vw_CitasMedicas");
            entity.Property(x => x.IdCita).HasColumnName("ID_CITA");
            entity.Property(x => x.IdPaciente).HasColumnName("ID_PACIENTE");
            entity.Property(x => x.Paciente).HasColumnName("PACIENTE");
            entity.Property(x => x.IdDoctor).HasColumnName("ID_DOCTOR");
            entity.Property(x => x.Doctor).HasColumnName("DOCTOR");
            entity.Property(x => x.IdEspecialidad).HasColumnName("ID_ESPECIALIDAD");
            entity.Property(x => x.Especialidad).HasColumnName("ESPECIALIDAD");
            entity.Property(x => x.FechaHora).HasColumnName("FECHAHORA");
        });

    }
}
