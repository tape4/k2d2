from flask import Flask, request, jsonify
import os
import subprocess
import wget

from detect_ import load_model, run_model

app = Flask(__name__)

weights_path = '/home2/rionking12/yolov5/best.pt'
nextcloud_url = ''
nextcloud_user = ''  # Nextcloud 사용자 이름
nextcloud_password = '' 


# 1. 모델 가중치 및 설정 정보
loaded_resources = load_model(weights_path)

# 2. 이미지 다운로드 및 모델 추론 함수
def download_image(image_url):
    # image_url = nextcloud_url + image_name
    image_name = image_url.split("/")[-1]
    image_path = os.path.join("./tmp", image_name)  # /tmp 디렉토리 사용

    # wget으로 ID와 비밀번호를 사용하여 다운로드
    command = f'wget --user={nextcloud_user} --password={nextcloud_password} {image_url} -O {image_path}'
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    
    # 다운로드 에러 처리
    if result.returncode != 0:
        raise Exception(f"Failed to download image: {result.stderr}")
    
    return image_path

def run_detection(image_path):
    # YOLOv5 모델을 사용하여 추론 수행
    result = run_model(weights=weights_path, source=image_path, **loaded_resources)
    # command = f'/home2/rionking12/yolov5/venv/bin/python3 /home2/rionking12/yolov5/detect_.py --weights {weights_path} --img 640 --conf 0.4 --source {image_path}'
    # result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    print(result)
    return result

# 3. POST /detect 엔드포인트 설정
# GET/ detect
@app.route('/detect', methods=['GET'])
def detect():
    image_url = request.args.get('url')
    # image_name = request.args.get('file')
    
    if not image_url:
        return jsonify({'error': 'Image file name not provided'}), 400

    try:
        # 이미지 다운로드
        image_path = download_image(image_url)

        # 모델 추론
        if (run_detection(image_path)):
            detection_result = True
        else:
            detection_result = False
        # detection_result = run_detection(image_path)
        print(detection_result)
        # 추론 결과 반환
        return jsonify({'result': detection_result}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 4. 서버 실행
if __name__ == '__main__':
    app.run(debug=True)
