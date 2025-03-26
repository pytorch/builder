FROM python:3.8-alpine
WORKDIR /work
ADD requirements.txt .
RUN pip install -r requirements.txt
ADD manage.py .
ENTRYPOINT ["python", "/work/manage.py"]
