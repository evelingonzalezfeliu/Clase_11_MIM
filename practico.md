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
