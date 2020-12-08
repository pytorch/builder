FROM python:3.8
WORKDIR /work
ADD requirements.txt .
RUN pip install -r requirements.txt
ADD manage.py .
ENTRYPOINT ["python", "manage.py"]
