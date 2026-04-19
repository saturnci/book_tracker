require "rails_helper"

describe "Authors", type: :request do
  describe "GET /authors" do
    it "returns a 200 response" do
      get authors_path
      expect(response).to have_http_status(:ok)
    end
  end
end
