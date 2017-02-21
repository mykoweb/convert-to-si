def good_units
  {
    'degree/min'             => 'rad/s',
    '(degree/min)'           => '(rad/s)',
    '((((degree/min))))'     => '((((rad/s))))',
    '(((((degree)/(min)))))' => '(((((rad)/(s)))))',
    '((degree))/min'         => '((rad))/s',
    'degree/(((min)))'       => 'rad/(((s)))',
    '(degree)/(min)'         => '(rad)/(s)'
  }
end

describe Converter do
  describe '#new' do
    context 'with the wrong units' do
      it 'raises a MalformedUnitError' do
        expect do
          described_class.new 'zebra'
        end.to raise_error MalformedUnitError
      end
    end

    context 'with spaces in the units' do
      it 'raises a MalformedUnitError' do
        expect do
          described_class.new 'tonne * day'
        end.to raise_error MalformedUnitError
      end
    end
  end

  describe '#units' do
    context 'with no units' do
      let(:converter) { described_class.new '' }

      it 'returns the empty string' do
        expect(converter.units).to eq ''
      end
    end

    context 'with valid units' do
      let(:units)     { 'MIN*MIN/(((HOUR*T)))' }
      let(:converter) { described_class.new units }

      it 'returns the correct units' do
        expect(converter.units).to eq units.downcase
      end
    end
  end

  describe '#unit_name' do
    context 'with a complex unit' do
      let(:unit) { '(degree)/(minute*day)' }

      it 'returns the correct converted units' do
        expect(described_class.new(unit).unit_name).to eq '(rad)/(s*s)'
      end
    end

    context 'with various combinations of well-formed parentheses' do
      good_units.each do |unit, converted_unit|
        it 'returns the correct converted units' do
          expect(described_class.new(unit).unit_name).to eq converted_unit
        end
      end
    end
  end

  describe '#mult_factor' do
    context 'with a complex unit' do
      [
        '(degree)/(minute*(day))',
        '(degree)/((minute)*day)',
        'degree/(minute*(day))',
        'degree/((minute)*day)'
      ].each do |unit|
        it 'returns the correct multiplication factor' do
          expect(described_class.new(unit).mult_factor.round(14)).to eq 0.000_000_003_366_76
        end
      end
    end

    context 'with another complex unit' do
      [
        '(min*min*min)/min',
        '((min)*min*min)/min',
        '(min*(min)*min)/min',
        '(min*min*(min))/min',
        '((min*min)*min)/min',
        '(min*(min*min))/min',
        '(min*(min*min))/(min)'
      ].each do |unit|
        it 'returns the correct multiplication factor' do
          expect(described_class.new(unit).mult_factor.round(14)).to eq 3600.0
        end
      end
    end

    context 'with yet another complex unit' do
      [
        'h/(h*h*h)',
        'h/((h)*h*h)',
        'h/(h*(h)*h)',
        'h/(h*h*(h))',
        'h/((h*h)*h)',
        'h/(h*(h*h))',
        '((h))/(h*(h*h))'
      ].each do |unit|
        it 'returns the correct multiplication factor' do
          expect(described_class.new(unit).mult_factor.round(14)).to eq 0.000_000_077_160_49
        end
      end
    end

    context 'with various combinations of well-formed parentheses' do
      good_units.each do |unit, _converted_unit|
        it 'returns the correct multiplication factor' do
          expect(described_class.new(unit).mult_factor.round(14)).to eq 0.00029088820867
        end
      end
    end

    context 'with a really crazy unit' do
      let(:unit) { '((degree*°)/degree)/degree*(degree)/degree*(degree)/(minute*((day)))*degree' }

      it 'returns the correct converted units' do
        expect(described_class.new(unit).unit_name).to eq '((rad*rad)/rad)/rad*(rad)/rad*(rad)/(s*((s)))*rad'
      end

      it 'returns the correct multiplication factor' do
        expect(described_class.new(unit).mult_factor.round(14)).to eq 0.000_000_000_058_76
      end
    end

    context 'with a time divided by mass unit' do
      let(:unit) { 'min/t' }

      it 'returns the correct multiplication factor' do
        expect(described_class.new(unit).mult_factor.round(14)).to eq 0.06
      end
    end
  end
end
