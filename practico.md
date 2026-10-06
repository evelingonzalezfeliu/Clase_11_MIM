## 1. Crear la carpeta de trabajo

Crea una carpeta en tu **home** para guardar el script Bash de ANNOVAR:

```bash
cd ~
mkdir -p practico_variantes
cd practico_variantes
```

Los archivos de entrada están en `~/strelka_persample`. Comprueba cuántos VCF hay:

```bash
ls ~/strelka_persample/*.variants.vcf.gz | wc -l
```

**Resultado esperado:**

```text
83
```

## 2. Anotar variantes con ANNOVAR

Utilizaremos todos los archivos `*.variants.vcf.gz` de `~/strelka_persample`, que contiene las 15 muestras del práctico.

### Crear el script de SLURM

Desde la carpeta de trabajo:

```bash
cd ~/practico_variantes
nano sbatch.run.annovar.sh
```

Copia el siguiente contenido:

```bash
#!/bin/bash
#SBATCH --job-name=annovar_15
#SBATCH --output=annovar.%A_%a.out
#SBATCH --error=annovar.%A_%a.err
#SBATCH --array=1-15
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

set -euo pipefail

ANNOVAR="/mnt/beegfs/labs/DiGenomaLab/databases/annovar/annovar/table_annovar.pl"
DB="/mnt/beegfs/labs/DiGenomaLab/databases/annovar/hg38"

cd "$SLURM_SUBMIT_DIR"
mkdir -p output

# Obtener los VCF directamente desde la carpeta de entrada.
mapfile -t VCFS < <(
    printf '%s\n' "$HOME"/strelka_persample/*.variants.vcf.gz |
    sort -V
)

# Cada tarea del array procesa una muestra.
VCF="${VCFS[$((SLURM_ARRAY_TASK_ID - 1))]}"
MUESTRA=$(basename "$VCF" .variants.vcf.gz)

echo "Anotando: $MUESTRA"

perl "$ANNOVAR" "$VCF" "$DB" \
    -out "output/${MUESTRA}.annovar" \
    -buildver hg38 \
    -vcfinput \
    -protocol ensGene,gnomad41_exome,gnomad41_genome,avsnp151,clinvar_20250721,dbnsfp47a,revel \
    -operation g,f,f,f,f,f,f \
    -nastring . \
    -polish \
    -otherinfo \
    -remove
```

Guarda con `Ctrl + O`, presiona `Enter` y sal con `Ctrl + X`.

### Ejecutar el análisis

```bash
sbatch sbatch.run.annovar.sh
```

El array ejecutará **15 tareas**, una por VCF.

Revisa su estado:

```bash
squeue -u "$USER"
```

### Comprobar los resultados

Cuando termine el análisis:

```bash
ls output/*.hg38_multianno.txt | wc -l
```

**Resultado esperado: 15 tablas.**

Cada muestra tendrá una tabla `*.hg38_multianno.txt` para analizar en R y un VCF anotado `*.hg38_multianno.vcf`.

Visualiza una tabla:

```bash
head -n 5 output/17.annovar.hg38_multianno.txt
```

**Pregunta:** ¿qué columnas describen la consecuencia de la variante, su frecuencia poblacional y la evidencia clínica?
