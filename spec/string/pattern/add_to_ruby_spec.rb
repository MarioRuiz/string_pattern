require "string_pattern"

RSpec.describe StringPattern, "#add_to_ruby" do
    describe 'array class' do
        it 'responds to generate' do
            expect(['uno','2:n'].generate).to match(/uno[0-9]{2}/)
        end
        it 'responds to gen' do
            expect(['uno','2:n'].gen).to match(/uno[0-9]{2}/)
        end
        it 'responds to validate' do
            expect(['uno','2:n'].validate('uno33')).to eq true
        end
        it 'responds to val' do
            expect(['uno','2:n'].val('uno33')).to eq true
        end        
    end

    describe 'string class' do
        it 'responds to generate' do
            expect('2:n'.generate).to match(/[0-9]{2}/)
        end
        it 'responds to gen' do
            expect('2:n'.gen).to match(/[0-9]{2}/)
        end
        it 'responds to validate' do
            expect('2:n'.validate('33')).to eq []
        end
        it 'responds to val' do
            expect('2:n'.val('33')).to eq []
        end
        it 'responds to to_camel_case' do
            expect('ccccc aaa'.to_camel_case).to eq 'CccccAaa'
        end
    end

    describe 'symbol class' do
        it 'responds to generate' do
            expect(:'2:n'.generate).to match(/[0-9]{2}/)
        end
        it 'responds to gen' do
            expect(:'2:n'.gen).to match(/[0-9]{2}/)
        end
        it 'responds to validate' do
            expect(:'2:n'.validate('33')).to eq []
        end
        it 'responds to val' do
            expect(:'2:n'.val('33')).to eq []
        end
    end

    describe 'regexp class' do
        it 'responds to generate' do
            expect(/\d{2}/.generate).to match(/[0-9]{2}/)
        end
        it 'responds to gen' do
            expect(/\d{2}/.gen).to match(/[0-9]{2}/)
        end
        it 'responds to to_sp' do
            expect(/\d{2}/.to_sp).to eq '2:n'
        end

    end

    describe 'from Kernel' do
        it 'responds to generate' do
            expect(generate('2:N')).to match(/[0-9]{2}/)
        end
        it 'responds to gen' do
            expect(gen('2:N')).to match(/[0-9]{2}/)
        end

    end

end