function W = func_der(x,xc,p)

% Esercitazione di 'Metodi Numerici in Ingegneria Aerospaziale'
% 15 ottobre 2013
% Prof. G. Coppola
% 
% Function per il calcolo dei pesi delle formule di derivazione mediante il
% metodo dei coefficienti indeterminati.
%
% Parametri di ingresso:
% x    -->    Vettore di coordinate dei nodi del mesh.
% xc   -->    Punto di collocazione delle derivate.
% p    -->    Ordine di derivazione della formula richiesta.
% 
% Parametri di uscita:
% W    -->    Riga dei pesi delle derivate o, se nargin = 2, matrice
%             contenente sulla j-ma riga i pesi della derivata j-1.

s   = length(x);          % s � il numero di nodi dello stencil.
x   = x(:).';             % Rendiamo il vettore x una riga. 
csi = x - xc;             % Definiamo la variabile ausiliaria x-xc.
A   = zeros(s);           % Allocazione della matrice A.
% Composizione della matrice.
for j = 1:s
    A (j,:) = csi.^(j-1)/factorial(j-1);
end
I = eye(s);               % Matrice identica.
% Risoluzione del sistema per i pesi di tutte le derivate (se � fornito p, 
% il termine noto per i pesi della derivata di ordine p sar� la (p+1)-ma 
% colonna della matrice identica).
W = A\I;                  % Risoluzione del sistema.
W = W.';                  % Mettiamo i pesi sulle righe.
% Se richiesto, estraiamo solo i pesi della p-ma derivata (NB la presente
% versione non � 'ottimizzata', poich� calcola in ogni caso i pesi di tutte
% le derivate, anche se � richiesta solo la derivata di ordine p).
if nargin==3
    W = W(p+1,:);
end
