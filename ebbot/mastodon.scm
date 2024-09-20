(define-module (babweb lib mastodon) 
 #:use-module (babweb lib env)
 #:use-module (web client)
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (web response)
 #:use-module (web request)
 #:use-module (oop goops) ;; class-of
 #:use-module (web uri)
 #:use-module (web client)
 #:use-module (web http)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (babweb lib image)
 #:use-module (babweb lib utilities)
 
 #:export (
	   mast-post-toot-curl-recurse
	   mast-post-image-curl
	   mastodon-runner
	   main
	   ))


(define *oauth-consumer-key* (@@ (babweb lib env) *oauth-consumer-key*))
(define *oauth-consumer-secret* (@@ (babweb lib env) *oauth-consumer-secret*))
(define *bearer-token* (@@ (babweb lib env) *bearer-token*))  ;;this does not change
(define *oauth-access-token* (@@ (babweb lib env) *oauth-access-token*))
(define *oauth-token-secret* (@@ (babweb lib env) *oauth-token-secret*))
(define *client-id* (@@ (babweb lib env) *client-id*))
(define *client-secret* (@@ (babweb lib env) *client-secret*))

(define *working-dir* (@@ (babweb lib env) *working-dir*))
(define *tweet-length* (@@ (babweb lib env) *tweet-length*))




;;curl -v -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -X POST -H 'Content-Type: multipart/form-data' https://mastodon.social/api/v2/media --form file='@/home/mbc/projects/babdata/archive/fakenewshist.jpeg'
(define (mast-post-image-curl i)
  (let*(
	(bearer (string-append "'Authorization: Bearer " *bearer-token* "'"))
	(image (string-append "file='@" i "'"))
	(out-file (get-rand-file-name "f" "txt"))
;;	(_ (pretty-print (string-append " *wd* in post-image-curl: " *working-dir*)))
;;	(_ (pretty-print (string-append "getcwd in post-image-curl: " (getcwd))))
	
	(command (string-append "curl -o " out-file " -X POST -H " bearer " -H 'Content-Type: multipart/form-data' https://mastodon.social/api/v2/media --form " image))
	(_ (system command))
	(_ (sleep 3))
	(p  (open-input-file out-file))
	(lst  (json-string->scm (get-string-all p)))
	(id (assoc-ref lst "id"))
	(_ (delete-file out-file))
      )
  id  ))


;; (define (mast-post-toot-curl t i)
;;   (let*((media-id (mast-post-image-curl i))
;; 	(media (string-append "' -F 'media_ids[]=" media-id "'"))
;; 	(pref "curl https://mastodon.social/api/v1/statuses -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -F 'status=")
;; 	(suff "'")
;; 	(command (string-append pref t media))
;; 	(_ (pretty-print command))
;; 	)
;;   (system command)  )
;;   )


(define (mast-post-toot-curl t i)
  (let*((media-id (mast-post-image-curl i))
	(status (string-append " -F 'status=" t "'"))
	(pref "curl https://mastodon.social/api/v1/statuses -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -F 'media_ids[]=")
	(suff "'")
	(command (string-append pref media-id status))
	(_ (pretty-print command))
	)
  (system command)  )
  )

;; curl -X POST \
;; 	-F 'client_id=your_client_id_here' \
;; 	-F 'client_secret=your_client_secret_here' \
;; 	-F 'redirect_uri=urn:ietf:wg:oauth:2.0:oob' \
;; 	-F 'grant_type=authorization_code' \
;; 	-F 'code=user_authzcode_here' \
;; 	-F 'scope=read write push' \
;; 	https://mastodon.example/oauth/token


(define (mastodon-get-access-post)
;;I already have the authorization code - now get access code
  (let* ((url "https://mastodon.social/oauth/token?")
	 (client-id *client-id*)
	 (suffix "&scope=write:statuses&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code")
(full-url (string-append url client-id suffix))
	 )
     (receive (response body)	  
	 (http-post full-url )
;;       (pretty-print (json-string->scm (utf8->string body))))
       (pretty-print (json-string->scm  body)))
    )

  )

(define (mast-post-toot-curl t i r)
  ;;t: text
  ;;i: media-id or #f
  ;;r: reply-id or #f
  (let*(;;(media-id (mast-post-image-curl i))
	(media (if i (string-append "' --data-binary 'media_ids[]=" i ) ""))
	(reply (if r (string-append "' --data-binary 'in_reply_to_id=" r ) ""))
	(suffix "'")
	(out-file (get-rand-file-name "f" "txt"))
	(command (string-append "curl -o " out-file " https://mastodon.social/api/v1/statuses -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' --data-binary 'status=" t media reply suffix))
	(_ (system command))
	(_ (sleep 3))
	(p  (open-input-file out-file))
	(lst  (json-string->scm (get-string-all p)))
;;      	(in (open-pipe*  OPEN_READ "curl" "-v" "-o" out-file "-H" bearer "-X" "POST" "-H" "'Content-Type: multipart/form-data'" "https://mastodon.social/api/v2/media" "--form" image))
	(id (assoc-ref lst "id"))
	(_ (delete-file out-file))
;;	(_ (pretty-print (string-append "post id: " id)))
	)
  id  ))

(define (mast-post-toot-curl-recurse lst reply-id media-id counter hashtags)
  ;;list of tweets to post
  ;;reply-id initially ""
  ;;counter initially 0; counter is needed to identify reply-id in first round and use media-id if exists
  ;;hashtags: "#uniparty #fakenews #misinformation #disinformation #propaganda"
  (if (null? (cdr lst))
	(mast-post-toot-curl (string-append (car lst) " " hashtags)  media-id reply-id);; last or only toot
      (if (eqv? counter 0) ;;the first toot with image and hashtags
	  (let* (;;(toot (string-append (car lst) " " hashtags))
		 (new-reply-id (mast-post-toot-curl (car lst) media-id reply-id))
		 (_ (set! counter (+ counter 1)))
		 )
	      ;; (pretty-print (cdr lst))
	      ;; (pretty-print (assoc-ref  (json-string->scm (utf8->string body)) "id_str"))
	      ;; (pretty-print media-id)
	      ;; (pretty-print counter)

	    (mast-post-toot-curl-recurse  (cdr lst)  new-reply-id #f counter hashtags)		
	    )
	  (let* ((new-reply-id (mast-post-toot-curl (car lst) #f reply-id))
		 (_ (set! counter (+ counter 1))))
	    (mast-post-toot-curl-recurse  (cdr lst) new-reply-id #f counter hashtags)))))


(define (mastodon-runner)
(let* ( ;;(_ (get-envs))
	  (counter (get-counter))
	  (all-excerpts (get-all-excerpts-alist))
	  (max-id (assoc-ref (car all-excerpts) "id"))
	  (new-counter (if (= counter max-id) 0 (+ counter 1)))
          (entity (find-by-id all-excerpts new-counter))	 
	  (tweets (chunk-a-tweet (assoc-ref entity "content") *tweet-length*))
	  (hashtags (get-all-hashtags-string))

	  (media-directive (assoc-ref entity "image"))
	  (image-file (if (string=? media-directive "none") #f (get-image-file-name media-directive)))
	  (media-id (if image-file (mast-post-image-curl image-file) #f))
	  (_ (set-counter new-counter)))
    (mast-post-toot-curl-recurse tweets #f media-id 0 hashtags)
	 )
  )

(define (main args)
 (mastodon-runner))

;;;;;
;;unused
;;;

(define (mast-oauth2-get-access )
  (let* (
	;; (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	;; (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
	;; (data (string-append "{\"text\": \"" text "\"}"))
 	 (uri  "https://mastodon.social/oauth/token")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						  (client_id . ,*oauth-consumer-key*)
							  (client_secret . ,(get-nonce 20 ""))
							  (redirect_uri . "urn:ietf:wg:oauth:2.0:oob")
							
							   (grant_type . "authorization_code")
							   (code . ,*authorization-code*)
							   (scope . "write:statuses")
							  ; (Content-type . "application/json")
							  ; (json . ,data)
							   )))
;;	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
;;	 (dummy (oauth-request-add-param tweet-request 'content-type "application/json"))
;;	 (dummy (oauth-request-add-param tweet-request 'Authorization "Bearer"))
;;	 (dummy (oauth-request-add-param tweet-request 'scope "tweet.write"))
	 
	 )
    #f))
