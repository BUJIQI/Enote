from flask import Blueprint, request, jsonify, send_file
import subprocess
import time
from werkzeug.utils import secure_filename
import os
import cv2

omr_bp = Blueprint('omr', __name__)

def preprocess_image(image_path):
    print("🔧 开始图像预处理:", image_path)
    img = cv2.imread(image_path)

    if img is None:
        print("❌ 无法读取图像:", image_path)
        return
    img = cv2.resize(img, None, fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC)
    print("🔍 图像已放大 2 倍")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    cv2.imwrite(image_path, gray)
    print("✅ 图像预处理完成")



@omr_bp.route('/omr', methods=['POST'])
def do_omr():
    if 'file' not in request.files:
        return jsonify({'error': '没有文件部分'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': '未选择文件'}), 400

    if file:
        # 保存上传文件
        time_flag = time.strftime(r"%Y%m%d%H%M%S")
        filename, ext = os.path.splitext(file.filename)
        new_filename = secure_filename(f"{filename}_{time_flag}{ext}")
        folder_path = "src/audiveris/omr_tmp"
        os.makedirs(folder_path, exist_ok=True)
        file_path = os.path.join(folder_path, new_filename)
        file.save(file_path)

        # 图像预处理（包含放大 + 灰度 + 去噪 + 二值化）
        preprocess_image(file_path)

        # 设置 OCR 路径
        env = os.environ.copy()
        env['TESSDATA_PREFIX'] = 'src\\audiveris\\tessdata'

        # 调用 audiveris
        command = (
            f'src\\audiveris\\bin\\audiveris.bat '
            f'@src/audiveris/cli.txt '
            f'src/audiveris/omr_tmp/{new_filename}'
        )

        print("🎼 OMR识别开始")
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True,  # ✅ 关键：运行 .bat 脚本需要 shell
            env=env, 
            encoding='utf-8', 
            errors='replace' 
        )
        stdout, stderr = process.communicate()
        process.wait()
        print("🎼 OMR识别结束\n", stdout, stderr, "over")

        # 构建 MXL 路径
        base_name = os.path.splitext(new_filename)[0]
        BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        SERVER_DIR = os.path.abspath(os.path.join(BASE_DIR, "..", ".."))
        mxl_file_path = os.path.join(SERVER_DIR, "src", "audiveris", "output", f"{base_name}.mxl")

        if os.path.exists(mxl_file_path):
            return send_file(
                mxl_file_path,
                mimetype="application/vnd.recordare.musicxml",
                as_attachment=True,
                download_name=f"{base_name.split('_')[0]}.mxl"
            )
        else:
            return jsonify({"error": "MXL 文件未生成"}), 500

    return jsonify({'error': '文件格式不支持'}), 400
