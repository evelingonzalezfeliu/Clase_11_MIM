library(maftools)

# Instalar BiocManager si no está disponible
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

# Instalar maftools si no está disponible
if (!requireNamespace("maftools", quietly = TRUE)) {
  BiocManager::install("maftools", update = FALSE, ask = FALSE)
}


## CAMBIAR
setwd("/mnt/beegfs/home/efeliu/work2026/practico_variantes/")
filenames <- Sys.glob("output2/*hg38_multianno.txt")
annovar_mafs = lapply(filenames, annovarToMaf, table = "ensGene", ens2hugo = FALSE, refBuild = "hg38")
annovar = data.table::rbindlist(l = annovar_mafs, fill = TRUE)
vcNames <- c("Frame_Shift_Del", "Frame_Shift_Ins", "Missense_Mutation", "Nonsense_Mutation", "Silent")
laml= read.maf(maf = annovar, vc_nonSyn = vcNames)
write.table(annovar, file="ADN_variants.tsv", sep = "\t", row.names = F)

# Revisar las clasificaciones disponibles
table(annovar$CLNSIG)
table(annovar$Hugo_Symbol)

patogenicas <- annovar[!is.na(CLNSIG) & CLNSIG == "Pathogenic"]

columnas <- c(
  "Tumor_Sample_Barcode",
  "Hugo_Symbol",
  "Chromosome",
  "Start_Position",
  "Reference_Allele",
  "Tumor_Seq_Allele2",
  "Variant_Classification",
  "aaChange",
  "gnomad41_exome_AF",
  "gnomad41_genome_AF",
  "avsnp151",
  "CLNSIG",
  "CLNREVSTAT",
  "CLNDN",
  "REVEL_score",
  "SIFT_pred")

# Seleccionar las columnas disponibles en la tabla
patogenicas_discusion <- patogenicas[
  , intersect(columnas, names(patogenicas)),
  with = FALSE
]

table(annovar$CLNSIG)
table(annovar$Hugo_Symbol)
#View(patogenicas_discusion)

plotmafSummary(maf = laml, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE)

lollipopPlot(
  maf = laml,
  gene = "BRCA1",
  AACol = "aaChange",
  showMutationRate = FALSE)

lollipopPlot(
  maf = laml,
  gene = "BRCA2",
  AACol = "aaChange",
  showMutationRate = FALSE)