# Podman LaTeX 编译环境

本项目使用一个轻量 TinyTeX 容器编译论文，避免在 Windows 主机安装完整 TeX Live。

## 1. 启动 Podman machine

```powershell
podman machine start podman-machine-default
```

## 2. 构建 LaTeX 镜像

首次使用需要构建一次镜像：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\scripts\build_latex_container.ps1
```

镜像名默认为：

```text
localhost/hnu-thesis-latex:tiny
```

该镜像基于 `debian:bookworm-slim` 和 TinyTeX，只安装当前论文需要的 XeLaTeX、ctex、TikZ/PGFPlots、gbt7714、latexmk 等包。

## 3. 编译论文

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\scripts\compile_latex_podman.ps1
```

脚本会先刷新第 5 章实验数据宏，然后在容器中编译 `src/main.tex`。

输出文件：

```text
src/build/main.pdf
src/build/main.synctex.gz
src/main.pdf
src/main.synctex.gz
```

`main.synctex.gz` 用于 LaTeX Workshop 在 PDF 和 LaTeX 源码之间跳转。由于编译发生在容器内，脚本会自动把 SyncTeX 中的 `/work` 容器路径改写为 Windows 主机上的 `src` 目录路径。

## 4. 清理辅助文件

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\scripts\compile_latex_podman.ps1 -Clean
```
