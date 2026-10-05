# Fonts

Both fonts come from Google Fonts and use the SIL Open Font License (the `OFL-*.txt` files here).

| File | Source | Settings |
|---|---|---|
| `Fraunces-SemiBold.ttf` | `ofl/fraunces/Fraunces[SOFT,WONK,opsz,wght].ttf` | `wght=600 opsz=28 SOFT=50 WONK=0` |
| `Inter-Regular.ttf` | `ofl/inter/Inter[opsz,wght].ttf` | `wght=400 opsz=14` |
| `Inter-Medium.ttf` | same | `wght=500 opsz=14` |
| `Inter-SemiBold.ttf` | same | `wght=600 opsz=14` |

The sources are the variable fonts in https://github.com/google/fonts. Each file here is a static instance, because Flutter does not reliably map `FontWeight` onto a variable font's weight axis. With one file per weight, `copyWith(fontWeight: ...)` works as expected.

To add a weight, instance it with [fontTools](https://github.com/fonttools/fonttools) and list it in `pubspec.yaml`:

```bash
pip install fonttools
python3 -m fontTools.varLib.instancer 'Inter[opsz,wght].ttf' wght=700 opsz=14 -o Inter-Bold.ttf
```
