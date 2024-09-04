from flask import Flask, request, send_from_directory
import loguru
import os
import minato

app = Flask(__name__)

DOWNLOAD_LOCATION = os.environ.get("CACHED_LOCATION", os.path.join(os.path.dirname(os.path.abspath(__file__)), '.cached'))
os.makedirs(DOWNLOAD_LOCATION, exist_ok=True)
loguru.logger.warning(f'Cached dir {DOWNLOAD_LOCATION}')

# Define a function to handle POST requests
@app.route('/download', methods=['POST'])
def download_file():
    # Get the file name from the POST data
    file_name = request.form['file_name']
    loguru.logger.info(file_name)
    
    # loguru.logger.info(target_filename)
    try:
        _basename = minato.cached_path(url_or_filename=file_name, cache_root=DOWNLOAD_LOCATION, auto_update=bool(os.environ.get("AUTO_UPDATE", 0)), force_download=bool(os.environ.get("FORCE_DOWNLOAD", 0)), expire_days=os.environ.get("EXPIRE_DAYS", -1))
        _return_file = _basename.name 
    except Exception as e:
        loguru.logger.info(str(e))
        _return_file = ''

    # Return the file as an attachment
    return send_from_directory(DOWNLOAD_LOCATION, _return_file, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)

