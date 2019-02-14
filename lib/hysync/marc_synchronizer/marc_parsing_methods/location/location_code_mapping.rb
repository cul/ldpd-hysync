module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Location
        module LocationCodeMapping
          # From https://www.loc.gov/marc/languages/language_code.html
          LOCATION_TERMS_TO_CLIO_CODES = {
            {
              'value' => 'Art Properties, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/067ebe3c-c669-44df-929b-9e24cbaec902',
              'code' => 'NyNyCAP'
            } => ['avap'],
            {
              'value' => 'Augustus C. Long Health Sciences Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/ad20ac6d-4507-4995-82d0-5618e27aa890',
              'code' => 'NNC-M'
            } => [/^hsl.*/, /^hsx.*/],
            {
              'value' => 'Avery Architectural & Fine Arts Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/12c8f9a0-9a61-4cce-a09a-ceeb7ddf4f06',
              'code' => 'NNC-A'
            } => ['avda', 'ave', 'ave,anx2', 'ave,mura', 'ave,ps', 'ave,ref', 'ave,res', 'avelc ', 'avelc,ref', 'avr ', 'avr,cage', 'avr,rrm', 'avr,stor', 'faa', 'far', 'far,cage', 'far,rrm', 'far,stor', 'fax', 'fax,anx2', 'fax,ps', 'fax,ref', 'fax,res', 'faxlc', 'faxlc,ref', 'off,avda', 'off,ave', 'off,avr', 'war', 'war,anx2', 'war,ref', 'war,res'],
            {
              'value' => 'Barnard College Library',
              'uri' => 'http://id.library.columbia.edu/term/4ff8bec8-6d8c-460c-8d77-006805e98778',
              'code' => 'NNBa'
            } => [/^bar.*/],
            {
              'value' => 'Burke Library at Union Theological Seminary, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/4f175cc6-1394-49b9-a411-2fe143265d43',
              'code' => 'NyNyCBL'
            } => ['off,unr', 'off,uta', 'off,utmrl', 'off,utn', 'off,utp', 'off,uts', 'uts', 'uts,arc', 'uts,aud', 'uts,essxx1', 'uts,essxx2', 'uts,essxx3', 'uts,fic', 'uts,fil', 'uts,gil', 'uts,kit', 'uts,loc ', 'uts,locxxf', 'uts,mac', 'uts,macxfp', 'uts,macxxf ', 'uts,macxxp', 'uts,map', 'uts,mrld', 'uts,mrldr', 'uts,mrldxf', 'uts,mrlo', 'uts,mrlor', 'uts,mrloxf', 'uts,mrls', 'uts,mrlxxp', 'uts,mss', 'uts,per', 'uts,perr', 'uts,perrxf', 'uts,perxxf', 'uts,prs', 'uts,ref', 'uts,refr', 'uts,refx3a', 'uts,refxs1', 'uts,refxs2', 'uts,refxxa', 'uts,reled', 'uts,res', 'uts,review', 'uts,tms ', 'uts,twr', 'uts,twrxxf', 'uts,unn', ' uts,unnr', 'uts,unnrxf', 'uts,unnrxp', 'uts,unnxxf', 'uts,unnxxp', 'uts,vid'],
            {
              'value' => 'Butler Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/4fbd48a4-130b-4a5c-9949-0e8dc864af94',
              'code' => 'NNC'
            } => ['glx', 'glx,anx', 'glx,anx2', 'glx,fol', 'glx,rare', 'glxn', 'off,glx', 'ref', 'ref,ac10', 'ref,atl', 'ref,book', 'ref,case', 'ref,col', 'ref,dic', 'ref,ets', 'ref,ind', 'ref,mez', 'ref,off', 'ref,over', 'site', 'sls,cage', 'mil,anx2', 'mil,over', 'mil,stdy', 'morl', 'mrr', 'mrr,anx', 'said', 'sasi', 'ushi', 'afst', 'comp', 'euro', 'islm', 'manc', 'manc,dic'],
            {
              'value' => 'Columbia Center for Oral History, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/cd34331d-899b-444a-85c4-211e045fc2ea',
              'code' => 'NyNyCOH'
            } => ['oral', 'oral,dgtl', 'off,oral'],
            {
              'value' => 'C.V. Starr East Asian Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/d0642664-03aa-4dc4-8579-a9b04b23960f',
              'code' => 'NNC-EA'
            } => ['pren,eal', 'pren,eax', 'eal', 'off,eal', 'eal,anx', 'eal,anx2', 'eal,cage', 'eal,fol', 'eal,kres', 'eal,rare', 'eal,ref', 'eal,res', 'eal,sky', 'eal,spec', 'ean', 'ear', 'eax', 'eax,anx', 'eax,anx2', 'eax,cage', 'eax,fol', 'eax,hsl', 'eax,kres', 'eax,leh', 'eax,rare', 'eax,ref', 'eax,ref2', 'eax,res', 'eax,sem', 'eax,sky', 'eax,spec', 'eax,tib', 'off,ean', 'off,ear', 'off,eax'],
            {
              'value' => 'Gabe M. Wiener Music & Arts Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/7e0df318-f285-4ec2-9cdd-67ecd049e416',
              'code' => 'NyNyCMA'
            } => ['msc', 'msc,anx', 'msc,anx2', 'msc,case', 'msc,fol', 'msc,rare', 'msc,ref', 'msc,resc', 'msc,resp', 'msr', 'msr,anx2', 'msr,case', 'mus', 'mus,anx', 'mus,anx2', 'mus,case', 'mus,fol', 'mus,lib', 'mus,ref', 'mus,resp', 'off,msc', 'off,msr', 'off,mus'],
            {
              'value' => 'Rare Book & Manuscript Library, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/d2142d01-deaa-4a39-8dbd-72c4f148353f',
              'code' => 'NNC-RB'
            } => ['gax', 'rbi', 'rbms', 'rbx', 'off,rbms', 'off,rbx'],
            {
              'value' => 'University Archives, Columbia University',
              'uri' => 'http://id.library.columbia.edu/term/993db1bc-2347-4b0d-ab1c-d5714ec82683',
              'code' => 'NNC-UA'
            } => ['clm']
          }.freeze

          CLIO_EXACT_CODES_TO_LOCATION_TERMS = begin
            hsh = {}
            LOCATION_TERMS_TO_CLIO_CODES.each do |location_term, clio_codes|
              clio_codes.each do |clio_code|
                hsh[clio_code] = location_term if clio_code.is_a?(String)
              end
            end
            hsh
          end.freeze

          CLIO_REGEX_CODE_PATTERNS_TO_LOCATION_TERMS = begin
            hsh = {}
            LOCATION_TERMS_TO_CLIO_CODES.each do |location_term, clio_codes|
              clio_codes.each do |clio_code|
                hsh[clio_code] = location_term if clio_code.is_a?(Regexp)
              end
            end
            hsh
          end.freeze

          def clio_code_to_location_term(clio_code)
            # First, try matching against an exact code, since that's faster
            term = CLIO_EXACT_CODES_TO_LOCATION_TERMS[clio_code]
            return term unless term.nil?
            # Next, try matching against regular expression code patterns
            CLIO_REGEX_CODE_PATTERNS_TO_LOCATION_TERMS.each do |code_regexp, location_term|
              return location_term if code_regexp =~ clio_code
            end
            nil
          end
        end
      end
    end
  end
end
