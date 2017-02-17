describe App do
  describe 'GET /units/si' do
    context 'with no query params' do
      before { get '/units/si' }

      it 'returns 200' do
        expect(last_response).to be_ok
      end

      it 'returns correct json' do
        resp_body = JSON.parse last_response.body

        expect(resp_body['unit_name']).to eq ''
        expect(resp_body['multiplication_factor']).to eq 1.0
      end
    end

    context 'with the wrong query params' do
      before { get '/units/si?yoshi=true' }

      it 'returns 200' do
        expect(last_response).to be_ok
      end

      it 'returns correct json' do
        resp_body = JSON.parse last_response.body

        expect(resp_body['unit_name']).to eq ''
        expect(resp_body['multiplication_factor']).to eq 1.0
      end
    end

    context 'with bad units' do
      before { get '/units/si?units=california' }

      it 'returns 400' do
        expect(last_response).to be_bad_request
      end

      it 'returns correct json' do
        expect(last_response.body).to eq 'Bad Request: Malformed units query param'
      end
    end

    context 'with spaces in the units' do
      before { get '/units/si?units=degree / min' }

      it 'returns 400' do
        expect(last_response).to be_bad_request
      end

      it 'returns correct json' do
        expect(last_response.body).to eq 'Bad Request: Malformed units query param'
      end
    end

    context 'with malformed parentheses' do
      before { get '/units/si?units=((()' }

      it 'returns 400' do
        expect(last_response).to be_bad_request
      end

      it 'returns correct json' do
        expect(last_response.body).to eq 'Bad Request: Malformed Parentheses'
      end
    end

    context 'with correct query params' do
      before { get '/units/si?units=(second*ha)/(litre*tonne*h)' }

      it 'returns 200' do
        expect(last_response).to be_ok
      end

      it 'returns correct json' do
        resp_body = JSON.parse last_response.body

        expect(resp_body['unit_name']).to eq '(rad*m2)/(m3*kg*s)'
        expect(resp_body['multiplication_factor']).to eq 0.000_013_467_046_70
      end
    end
  end
end
