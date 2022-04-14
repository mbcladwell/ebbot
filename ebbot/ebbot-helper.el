
(global-set-key (kbd "<f6>") 'copy-content)

(defun copy-content()
  (interactive)
  (current-buffer)
  (copy-region-as-kill  (region-beginning) (region-end))
  (set-buffer "destination.txt")
  (insert  "\"")
  (yank)
  (insert "\"\n\n")
  (save-buffer 64))
 
  
  
