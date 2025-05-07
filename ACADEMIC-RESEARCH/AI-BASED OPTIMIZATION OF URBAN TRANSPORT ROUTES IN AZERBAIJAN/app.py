from flask import Flask, render_template, request, jsonify
import json

app = Flask(__name__)

with open("data/results.json") as f:
    results = json.load(f)

@app.route("/", methods=["GET", "POST"])
def index():
    return render_template("index.html")

@app.route("/calculate", methods=["POST"])
def calculate():
    if request.content_type != 'application/json':
        return jsonify({"error": "Unsupported Media Type"}), 415

    data = request.get_json()
    algorithm = data.get("algorithm")

    if algorithm == "all":
        return jsonify(results)

    result_data = results.get(algorithm)
    if result_data:
        response = dict(result_data) 
        response["algorithm"] = algorithm
        return jsonify(response)
    else:
        return jsonify({"error": "Algorithm not found"}), 404

if __name__ == "__main__":
    app.run(debug=True)
