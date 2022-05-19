(use-modules (ebbot ebbot))
 
(define (main args)
  ;;args:  ip port username password dbname method
  ;;first item of args list is the file name so skip
  ;;method: 'init' or 'refresh'  
  (init args))
	 

;; change to manifest
;; https://lists.gnu.org/archive/html/help-guix/2021-07/msg00037.html
