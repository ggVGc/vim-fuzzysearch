
let g:fuzzy_search_prompt='fuzzy /'


function! fuzzy_search#start_search()
  let obj = {}


  func obj.search() dict
    let c = ''
    let self.partial = ''
    while 1
      call self.update()
      let keyCode = getchar()
      let c = nr2char(keyCode)
      if c == "\<cr>"
        break
      elseif c == "\<esc>"
        let self.partial = ''
        call self.update()
        break
      elseif keyCode == 23 "CTRL-W
       let self.partial = substitute(self.partial, '[ ]*[^ ]*$', '', '')
      elseif c == ''
        let self.partial = self.partial[:-2]
      else
        let self.partial .= c
      endif
    endwhile
  endfunc


  func obj.update() dict
    let matchPat = substitute(substitute(self.partial, '\(\w\)', '\1\\w*', 'g'), '\.\*$', '', '')
    let matchPat = substitute(substitute(matchPat, ' ', '.*', 'g'), '\.\*$', '', '')
    if matchPat =~ '\.\*\$$'
      let matchPat = substitute(matchPat, '\.\*\$$', '$', '')
    endif
    let @/=matchPat
    exe "silent! norm! /" . matchPat . "\<cr>"
    redraw
    echo g:fuzzy_search_prompt. self.partial
  endfunc

  return obj
endfunction


command! -range -nargs=0 FuzzySearch call fuzzy_search#start_search().search()
