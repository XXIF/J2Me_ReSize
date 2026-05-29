#!/bin/bash
set -euo pipefail

# 彩色常量定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"

# 项目配置
PROJECT_NAME="J2ME 游戏画面适配工具 (Debian 版)"
REPO_URL="https://github.com/XXIF/J2Me_ReSize"
ASM_JAR="asm-4.0.jar"
ASM_URL="https://repo1.maven.org/maven2/org/ow2/asm/asm/4.0/asm-4.0.jar"
CLDC_JAR="cldcapi11.jar"
MIDP_LIB="midpapi20.jar"

# Adoptium Temurin 8 JDK（原生 x64，兼容所有现代 Linux）
JDK_TGZ="OpenJDK8U-jdk_x64_linux_hotspot_8u492b09.tar.gz"
JDK_ORIGIN="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u492-b09/${JDK_TGZ}"
JDK_MIRROR="https://github.dpik.top/https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u492-b09/${JDK_TGZ}"

# 双源下载配置（GitHub Raw）
ORIGIN_BASE="https://raw.githubusercontent.com/XXIF/J2Me_ReSize/main"
MIRROR_BASE="https://github.dpik.top/https://raw.githubusercontent.com/XXIF/J2Me_ReSize/main"

# 需要从项目仓库下载的文件
PROJECT_FILES=(
    "run.sh"
    "${CLDC_JAR}"
    "${MIDP_LIB}"
)

# 双源容错下载函数（小文件）
download_file() {
    local filename="$1"
    local origin_url="${ORIGIN_BASE}/${filename}"
    local mirror_url="${MIRROR_BASE}/${filename}"
    
    echo -e "      ${YELLOW}正在下载: ${filename}${RESET}"
    
    # 先尝试镜像地址（国内加速）
    if ! wget --timeout=15 -q "$mirror_url" -O "$filename"; then
        echo -e "      ${YELLOW}[提示] 镜像链接超时，切换官方地址${RESET}"
        if ! wget -q "$origin_url" -O "$filename"; then
            echo -e "      ${RED}[!] 下载失败: ${filename}${RESET}"
            return 1
        fi
    fi
    
    echo -e "      ${GREEN}[√] 下载成功${RESET}"
    return 0
}

# 通用大文件下载函数（支持断点续传 + 双源 + 大小校验）
download_large_file() {
    local filename="$1"
    local origin_url="$2"
    local mirror_url="$3"
    local min_bytes="$4"
    
    local dl_url
    for dl_url in "${mirror_url}" "${origin_url}"; do
        rm -f "${filename}.tmp"
        echo -e "      下载: ${dl_url}"
        
        if wget -c -q --timeout=180 -O "${filename}.tmp" "${dl_url}"; then
            sync 2>/dev/null || true
            local dl_size
            dl_size=$(stat -c%s "${filename}.tmp" 2>/dev/null || echo 0)
            if [ "${dl_size}" -gt "${min_bytes}" ]; then
                mv "${filename}.tmp" "${filename}"
                return 0
            else
                echo -e "      ${YELLOW}[提示] 文件过小 (${dl_size} bytes)，丢弃${RESET}"
                rm -f "${filename}.tmp"
            fi
        else
            rm -f "${filename}.tmp"
        fi
    done
    return 1
}

# 艺术标题
echo -e "${CYAN}=============================================${RESET}"
echo -e "${BLUE}        ${PROJECT_NAME}${RESET}"
echo -e "${CYAN}=============================================${RESET}"

# 检查 sudo 权限
echo -e "\n${YELLOW}[+] 检测权限${RESET}"
if ! sudo -v 2>/dev/null; then
    echo -e "      ${YELLOW}[提示] 需要 sudo 权限安装软件包${RESET}"
fi
echo -e "${GREEN}[√] 权限就绪${RESET}"

# 更新包列表并安装基础依赖
echo -e "\n${YELLOW}[+] 更新软件源${RESET}"
sudo apt-get update -y -qq 2>/dev/null
echo -e "${GREEN}[√] 软件源更新完成${RESET}"

echo -e "\n${YELLOW}[+] 安装基础工具${RESET}"
sudo apt-get install -y -qq wget unzip imagemagick ffmpeg python3 2>/dev/null
echo -e "${GREEN}[√] 基础工具就绪${RESET}"

# ========== Adoptium Temurin 8 JDK（原生 x64，全版本 Linux 兼容）==========
echo -e "\n${YELLOW}[+] 安装 OpenJDK 8 (Temurin)${RESET}"
JDK_DIR="$HOME/java/jdk8"

if java -version &>/dev/null; then
    JAVA_EXIST_VER=$(java -version 2>&1 | head -1 || echo "unknown")
    echo -e "      ${GREEN}[√] Java 已安装: ${JAVA_EXIST_VER}${RESET}"
elif [ -f "$JDK_DIR/bin/java" ]; then
    echo -e "      ${GREEN}[√] JDK 目录已存在，配置环境变量${RESET}"
else
    echo -e "      ${YELLOW}下载 Temurin 8 (~140MB, 请耐心等待)${RESET}"
    
    if download_large_file "${JDK_TGZ}" "${JDK_ORIGIN}" "${JDK_MIRROR}" 104857600; then
        echo -e "      正在解压安装..."
        
        rm -rf "$JDK_DIR" "$HOME/java/_extract" 2>/dev/null || true
        mkdir -p "$HOME/java" "$HOME/java/_extract"
        
        tar -xzf "${JDK_TGZ}" -C "$HOME/java/_extract" 2>/dev/null
        rm -f "${JDK_TGZ}"
        
        # 找到解压后的顶层目录（如 jdk8u492-b09）
        EXTRACTED_DIR=$(ls -d "$HOME/java/_extract"/*/ 2>/dev/null | head -1)
        if [ -n "$EXTRACTED_DIR" ] && [ -f "$EXTRACTED_DIR/bin/java" ]; then
            mv "$EXTRACTED_DIR" "$JDK_DIR"
        else
            # 降级搜索
            JAVA_BIN=$(find "$HOME/java/_extract" -name "java" -type f 2>/dev/null | head -1)
            if [ -n "$JAVA_BIN" ]; then
                mv "$(dirname "$(dirname "$JAVA_BIN")")" "$JDK_DIR"
            fi
        fi
        rm -rf "$HOME/java/_extract"
    fi
    
    if [ ! -f "$JDK_DIR/bin/java" ]; then
        echo -e "${RED}[!] JDK 安装失败${RESET}"
        exit 1
    fi
fi

# 配置环境变量
export JAVA_HOME="$JDK_DIR"
export PATH="$JDK_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$JDK_DIR/lib:$LD_LIBRARY_PATH"
hash -r 2>/dev/null || true

# 写入 ~/.bashrc（幂等）
if ! grep -q "JAVA_HOME" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'BASHEOF'
export JAVA_HOME="$HOME/java/jdk8"
export PATH="$JAVA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$JAVA_HOME/lib:$LD_LIBRARY_PATH"
BASHEOF
fi

# 创建 ~/bin/ 符号链接（Debian 默认 PATH 包含 ~/bin）
if [ -d "$HOME/bin" ] || ! [ -e "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
    for jbin in java javac jar; do
        [ -f "$JDK_DIR/bin/$jbin" ] && ln -sf "$JDK_DIR/bin/$jbin" "$HOME/bin/$jbin"
    done
fi

# 最终校验
if ! java -version &>/dev/null; then
    echo -e "${RED}[!] Java 环境不可用${RESET}"
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -1)
echo -e "      ${GREEN}[√] ${JAVA_VER}${RESET}"
echo -e "${GREEN}[√] Java (Temurin 8) 运行环境就绪${RESET}"

# ========== ASM 4.0 双源下载 ==========
echo -e "\n${YELLOW}[+] 下载 ASM 4.0 字节码库${RESET}"

if [ -f "${ASM_JAR}" ] && unzip -tq "${ASM_JAR}" 2>/dev/null; then
    echo -e "      ${GREEN}[√] ${ASM_JAR} 已存在且有效${RESET}"
else
    rm -f "${ASM_JAR}"
    echo -e "      下载: ${ASM_URL}"
    if ! wget -q --timeout=30 "${ASM_URL}" -O "${ASM_JAR}"; then
        echo -e "${RED}[!] ASM 4.0 下载失败${RESET}"
        echo -e "      可手动下载: ${ASM_URL}"
        exit 1
    fi
fi
echo -e "${GREEN}[√] ASM 4.0 就绪${RESET}"

# ========== 双源下载项目文件（run.sh + J2ME 标准库）==========
echo -e "\n${YELLOW}[+] 拉取项目文件${RESET}"

for file in "${PROJECT_FILES[@]}"; do
    if [ -f "${file}" ] && [ "${file}" = "run.sh" ]; then
        echo -e "      ${YELLOW}[提示] ${file} 已存在，将覆盖更新${RESET}"
        rm -f "${file}"
    fi
    
    if [ -f "${file}" ]; then
        # 校验 JAR 文件完整性
        if unzip -tq "${file}" 2>/dev/null; then
            echo -e "      ${GREEN}[√] ${file} 已存在且有效${RESET}"
        else
            echo -e "      ${YELLOW}[提示] ${file} 损坏，重新下载${RESET}"
            rm -f "${file}"
            download_file "${file}" || exit 1
        fi
    else
        download_file "${file}" || exit 1
    fi
done

chmod +x run.sh
echo -e "${GREEN}[√] 项目文件拉取完成${RESET}"

# 结束提示
echo -e "\n${CYAN}=============================================${RESET}"
echo -e "${GREEN}环境全部部署完毕！${RESET}"
echo -e "${BLUE}运行环境:${RESET}"
java -version 2>&1 | head -1
echo -e "${BLUE}编译工具:${RESET} ASM 4.0, CLDC 1.1, MIDP 2.0"
echo -e "${BLUE}项目地址:${RESET} ${REPO_URL}"
echo -e "${WHITE}\n执行命令：${PURPLE}./run.sh${WHITE} 开始处理JAR文件${RESET}"
echo -e "${CYAN}=============================================${RESET}"
