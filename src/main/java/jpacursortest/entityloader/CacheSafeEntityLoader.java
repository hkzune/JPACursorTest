package jpacursortest.entityloader;

import jakarta.persistence.Entity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.eclipse.persistence.config.QueryHints;
import org.eclipse.persistence.queries.CursoredStream;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * SELECTクエリの結果を、一次キャッシュの肥大化を抑制しつつ取得するためのクラス。
 *
 * @author unknown
 */
public class CacheSafeEntityLoader {

    private static final int CURSOR_CACHE_CLEAR_THRESHOLD = 500;

    /**
     * entityManagerを通じて、DBに対しqueryを実行する。<br>
     * QueryHints.CURSORを利用して、クエリの実行結果の代わりにカーソルを取得し、カーソルを操作して実行結果を取得する。<br>
     * 実行結果の取得ごとに、entityManagerの一次キャッシュから取得済のEntityを削除する。<br>
     * これにより、EntityManagerが大量のキャッシュを保持することを防ぐ。<br>
     * このメソッドには、entityManagerとqueryに対する破壊的な操作が含まれる。<br>
     *
     * @param <T> Entityクラスの型。
     * @param entityManager EntityManager。
     * @param query 実行するクエリ。
     * @return Entityのリスト。
     */
    public static <T> List<T> getUsingCursor(EntityManager entityManager, TypedQuery<T> query) {
        query.setHint(QueryHints.CURSOR, true);

        CursoredStream cursor = (CursoredStream) query.getSingleResult();

        List<T> result = new ArrayList<>();
        Boolean isEntity = null;
        int processedRow = 0;
        try {
            while (cursor.hasNext()) {
                @SuppressWarnings("unchecked")
                T entity = (T) cursor.next();

                result.add(entity);

                // TupleやIntegerなどのEntityクラスではないオブジェクトをdetachに渡すとIllegalArgumentExceptionとなるため事前にチェック
                if (Objects.nonNull(isEntity) ? isEntity : (isEntity = hasEntityAnnotation(entity.getClass()))) {
                    entityManager.detach(entity);
                }

                if(++processedRow % CURSOR_CACHE_CLEAR_THRESHOLD == 0) {
                    cursor.clear();
                    processedRow = 0;
                }
            }
        }
        finally {
            cursor.close();
        }

        return result;
    }

    private static boolean hasEntityAnnotation(Class<?> clazz) {
        Class<?> _clazz = clazz;
        while (_clazz != null && _clazz != Object.class) {
            // Entityアノテーションの有無で判断する
            if (_clazz.getAnnotation(Entity.class) != null) {
                return true;
            }
            _clazz = _clazz.getSuperclass();
        }
        return false;
    }

}
