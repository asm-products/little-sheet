import random
import settings
from flask import Flask, render_template, abort, redirect

app = Flask(__name__)
app.config.from_object(settings)

from boto.s3.connection import S3Connection
from boto.s3.key import Key
conn = S3Connection(settings.S3_KEY_ID, settings.S3_SECRET)
bucket = conn.get_bucket(settings.S3_BUCKET_NAME)

@app.route('/sheets/<sheet_id>', methods=['PUT'])
def save_sheet(sheet_id):
    data = request.get_json()
    if len(data['cells']) > 99 or len(data['cells'][0]) > 20:
        abort(406)

    sheet = {
        'cells': data['cells']
    }

    key = Key(bucket)
    key.key = sheet_id
    key.set_contents_from_string(
        json.dumps(sheet),
        policy='public-read',
        replace=True,
        headers={
            'Content-Type': 'application/json'
        }
    )

    return 'ok'

@app.route('/<sheet_id>')
def edit_sheet(sheet_id):
    return render_template('index.html', sheet_id=sheet_id)

@app.route('/')
def index():
    charset = 'zaqxswyawcdevfrkbgtenhaymuiujkilop'
    random_id = ''.join(random.choice(charset) for _ in range(8))
    return redirect('/' + random_id)

if __name__ == '__main__':
    app.run(host='0.0.0.0')
