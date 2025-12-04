import os
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
# Ensure the app directory is in the path
import LeadsManager

# Import the LeadsManager from the app module
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = Flask(
    __name__,
    template_folder=os.path.join(BASE_DIR, "website"),
    static_folder=os.path.join(BASE_DIR, "website"),
)

# Configure CORS to allow all origins, methods, and headers
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],  # Explicitly list methods
        "allow_headers": ["Content-Type", "Authorization"],      # Specify allowed headers
        "expose_headers": ["Content-Range", "X-Total-Count"],    # Headers client can read
        "supports_credentials": True,                            # Allow credentials
        "max_age": 3600                                         # Cache preflight for 1 hour
    }
})

@app.after_request
def add_header(response):
    """Add headers to disable caching."""
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/leads', methods=['GET'])
def get_leads():
    """Get all leads"""
    leads = LeadsManager.Get()
    return jsonify(leads), 200

@app.route('/leads', methods=['POST'])
def create_lead():
    """Create a new lead"""
    lead = request.get_json()
    if not lead:
        return jsonify({"error": "No data provided"}), 400

    updated_inventory = LeadsManager.Add(LeadsManager.Get(), lead)
    return jsonify({"message": "Lead created successfully", "data": lead}), 201

@app.route('/leads/<int:lead_id>', methods=['DELETE'])
def delete_lead(lead_id):
    """Delete a lead by ID"""
    updated_inventory = LeadsManager.Remove(LeadsManager.Get(), lead_id)
    return jsonify({"message": "Lead deleted successfully"}), 200

@app.route('/leads/<int:lead_id>', methods=['PUT'])
def update_lead(lead_id):
    """Update a lead by ID"""
    lead = request.get_json()
    if not lead:
        return jsonify({"error": "No data provided"}), 400

    updated_inventory = LeadsManager.Update(LeadsManager.Get(), lead_id, lead)
    return jsonify({"message": "Lead updated successfully", "data": lead}), 200


@app.route('/leads/close/<int:deal_id>', methods=['POST'])
def close_deal(deal_id):
    updated_inventory = LeadsManager.CloseDeal(LeadsManager.Get(), deal_id)
    return jsonify({"message": "Deal closed successfully"}), 200

@app.route('/')
def index():
    return render_template('index.html')

@app.route("/health")
def health():
    return {"status": "healthy"}, 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
