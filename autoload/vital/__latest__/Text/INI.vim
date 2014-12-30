let s:save_cpo = &cpo
set cpo&vim

let s:default_section = '_'
let s:comment_pattern = '\v[#;].*$'
let s:section_pattern = '\v^\s*\[\s*(.{-1,})\s*\]\s*$'
let s:parameter_pattern = '\v^\s*([^\=]{-1,})\s*\=\s*(.{-})\s*$'

function! s:parse_record(line) abort
  " remove comment string
  let line = substitute(a:line, s:comment_pattern, '', 'g')
  " is empty line?
  if line =~# '\v^\s*$'
    return {'type': 'emptyline'}
  endif
  " is parameter line?
  let m = matchlist(line, s:parameter_pattern)
  if len(m) > 0
    return {'type': 'parameter', 'key': m[1], 'value': m[2]}
  endif
  " is section line?
  let m = matchlist(line, s:section_pattern)
  if len(m) > 0
    return {'type': 'section', 'name': m[1]}
  endif
  " unknown format
  return {'type': 'unknown', 'value': line}
endfunction

function! s:parse(ini, ...) abort
  let fail_silently = get(a:000, 0, 1)
  let sections = {}
  let sections[s:default_section] = {}
  let current_section = s:default_section

  for line in split(a:ini, '\v%(\r?\n)+')
    let record = s:parse_record(line)
    if record.type ==# 'section'
      let current_section = record.name
      let sections[current_section] = get(sections, current_section, {})
    elseif record.type ==# 'parameter'
      let sections[current_section][record.key] = record.value
    elseif record.type ==# 'unknown' && !fail_silently
      throw 'vital: Text.INI: Parsing a record failed: ' . record.value
    endif
  endfor
  return sections
endfunction

function! s:parse_file(file, ...) abort
  let fail_silently = get(a:000, 0, 1)
  return s:parse(join(readfile(a:file), "\n"), fail_silently)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker