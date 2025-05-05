import os
import subprocess
import zipfile

# Kaggle API config
os.environ['KAGGLE_USERNAME'] = 'guzelben'      # <- buraya kullanıcı adını yaz
os.environ['KAGGLE_KEY'] = '3e2bd8a97af72fc1a9dbf82c6deaedba'            # <- kaggle.json içindeki key

# Veri setini indirmek için subprocess kullan
subprocess.run(['kaggle', 'datasets', 'download', '-d', 'mpwolke/venomous-non-venomous'])

# Zip dosyasını aç
with zipfile.ZipFile("venomous-non-venomous.zip", 'r') as zip_ref:
    zip_ref.extractall("dataset")
