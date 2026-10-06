# Clase_11_MIM

Práctico de la **Clase 11** del magíster (Universidad de Chile): anotación de variantes germinales a partir de VCFs de **Strelka2**, usando **ANNOVAR** y **CPSR** en un clúster con **SLURM**.

Pensado para personas que no vienen del área bioinformática: cada paso explica qué hace cada comando.

## Qué vamos a hacer

1. Conectarnos al clúster y preparar nuestra carpeta de trabajo.
2. Explorar los VCFs generados por Strelka2.
3. Enviar trabajos con SLURM (`sbatch`).
4. Anotar variantes con **ANNOVAR** (anotación funcional general).
5. Anotar variantes con **CPSR** (predisposición a cáncer).
6. Comparar los resultados de ambas herramientas.

## Contenido

- [`practico.md`](practico.md): guía paso a paso del taller.
- `scripts/`: scripts SLURM (`run_annovar.bash`, `run_CPSR.bash`).

## Requisitos

- Usuario en el clúster (`mim1` o `mim2`) y acceso por SSH.
- No se requiere experiencia previa en línea de comandos.
