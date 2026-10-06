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
#SBATCH --output=logs/annovar.%A_%a.out
#SBATCH --error=logs/annovar.%A_%a.err
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
    -remove  \
    > "logs/${MUESTRA}.annovar.log" 2>&1
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

## 3. Revisar los archivos de salida

Entra a la carpeta de resultados:

```bash
cd ~/practico_variantes/output
ls
```

Para cada muestra se generaron tres archivos:

| Archivo | Contenido |
|---|---|
| `*.avinput` | Archivo intermedio con las variantes en formato ANNOVAR |
| `*.hg38_multianno.txt` | Tabla de anotaciones que analizaremos en R |
| `*.hg38_multianno.vcf` | VCF con las anotaciones incorporadas |

### Comprobar las tablas generadas

```bash
ls *.hg38_multianno.txt | wc -l
```

**Resultado esperado: 15.**

### Explorar las columnas

Muestra los nombres de las columnas, uno por línea:

```bash
head -n 1 17.annovar.hg38_multianno.txt | tr '\t' '\n'
```

Identifica las siguientes anotaciones:

| Columnas | Información |
|---|---|
| `Chr`, `Start`, `End`, `Ref`, `Alt` | Posición y alelos de la variante |
| `Func.ensGene`, `Gene.ensGene` | Región y gen afectados |
| `ExonicFunc.ensGene`, `AAChange.ensGene` | Consecuencia exónica y cambio anotado por transcrito |
| `gnomad41_exome_AF`, `gnomad41_genome_AF` | Frecuencia alélica global en gnomAD |
| Columnas de frecuencia por población | Frecuencias en los distintos grupos de ancestría |
| `avsnp151` | Identificador de dbSNP |
| `CLNSIG` | Clasificación germinal reportada en ClinVar |
| `CLNREVSTAT` | Estado de revisión de ClinVar |
| `CLNDN` | Condiciones asociadas al registro de ClinVar |
| `SIFT_score`, `SIFT_pred` | Predicción de SIFT |
| `REVEL_score`, `REVEL` | Puntuaciones procedentes de dbNSFP y de la base REVEL, respectivamente |
| `Otherinfo*` | Campos adicionales, incluidos datos del VCF original |

El símbolo `.` indica que no hay una anotación disponible en ese campo; **no significa que la variante sea benigna**.

### Revisar una variante

Para visualizar las diez primeras columnas de la primera variante:

```bash
head -n 2 17.annovar.hg38_multianno.txt | cut -f 1-10
```

En el ejemplo mostrado encontramos:

- **Variante:** `chr13:32325251 A>C`.
- **Gen:** `BRCA2`.
- **Región:** intrónica.
- **dbSNP:** `rs11571610`.
- **Frecuencia en gnomAD:** 4,41 % en exomas y 4,11 % en genomas.
- **ClinVar:** benigna, con revisión por panel de expertos.

**Preguntas para discutir:**

1. ¿Es una variante rara o común?
2. ¿Qué evidencia respalda su interpretación?
3. ¿Por qué encontrar una variante en BRCA2 no implica que sea patogénica?
4. ¿Esperarías una puntuación REVEL para una variante intrónica?

En el siguiente paso importaremos las tablas en **R**, seleccionaremos las columnas relevantes y priorizaremos variantes.

## 4. Crear una sesión de R e instalar maftools

1. Ingresar a [Kutral](https://kutral-auth.uoh.cl/) con sus credenciales.
2. Crear una sesión de RStudio y abrirla.
3. Ejecutar los siguientes comandos en la consola de **R**.

### Instalar maftools

```r
# Instalar BiocManager si no está disponible
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

# Instalar maftools si no está disponible
if (!requireNamespace("maftools", quietly = TRUE)) {
  BiocManager::install("maftools", update = FALSE, ask = FALSE)
}
```

### Cargar el paquete y verificar la instalación

```r
library(maftools)
packageVersion("maftools")
```

Si el paquete se carga sin errores y muestra su versión, podemos continuar con el análisis de los archivos anotados con ANNOVAR.
