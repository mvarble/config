;; Ignore 4-space indented blocks in Markdown
((indented_code_block) @text)

; Header levels
(atx_h1_marker) @header.h1
(atx_h2_marker) @header.h2
(atx_h3_marker) @header.h3
(atx_h4_marker) @header.h4
(atx_h5_marker) @header.h5
(atx_h6_marker) @header.h6

; List markers
(list_marker_plus) @list
(list_marker_minus) @list
(list_marker_star) @list
