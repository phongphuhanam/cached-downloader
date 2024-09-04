from flask import Flask, request, send_from_directory
import loguru
import os

from urllib.parse import urlparse

def get_file_name_from_url(url):
    parsed_url = urlparse(url)
    return parsed_url.path.strip('/')

app = Flask(__name__)

# Define a function to handle POST requests
@app.route('/download', methods=['POST'])
def download_file():
    # Get the file name from the POST data
    file_name = request.form['file_name']
    loguru.logger.info(file_name)
    download_location = os.environ.get("CACHED_LOCATION", os.path.join(os.path.dirname(os.path.abspath(__file__)), '.cached'))
    os.makedirs(download_location, exist_ok=True)
    _basename = get_file_name_from_url(file_name)
    target_filename = os.path.join(download_location, _basename)
    if not os.path.isfile(target_filename):
        _cmd = f'curl --silent --fail {file_name} --output {target_filename}'
        os.system(_cmd)
        if os.path.isfile(target_filename):
            loguru.logger.info(f'Downloading {file_name} was success')
        else:
            loguru.logger.warning(f'Downloading {file_name} was unsuccessful. Please verify its availability.')
    else:
        loguru.logger.info(f'{_basename} existed.') 

    # Return the file as an attachment
    return send_from_directory(download_location, _basename, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)

