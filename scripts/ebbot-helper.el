
(global-set-key (kbd "<f6>") 'copy-content)

(defun copy-content()
  (interactive)
  (current-buffer)
  (copy-region-as-kill  (region-beginning) (region-end))
  (set-buffer "destination.txt")
 
  (yank)
  (insert "\n")
  (save-buffer 64))
 
  
  
